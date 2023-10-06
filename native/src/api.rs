use std::fs::File;
use std::io::Cursor;
use std::net::UdpSocket;
use std::time::Duration;
use flutter_rust_bridge::StreamSink;
use pcap_parser::*;
use pcap_parser::traits::PcapReaderIterator;
use crate::pcap_parser::framewriter::FrameWriter;
use crate::pcap_parser::vertexwriter::VertexWriter;

use super::pcap_parser::parse_packet_body;

pub struct PcdFrame {
    pub vertices: Vec<f32>,
    pub colors: Vec<f32>,
    pub other_data: Vec<f32>,
}

pub fn read_pcap_stream(stream: StreamSink<PcdFrame>, path: String) {
    let start = std::time::Instant::now();
    let file = File::open(path).unwrap();
    let mut reader = LegacyPcapReader::new(65536, file).unwrap();

    let mut writer = VertexWriter::create(stream);
    loop {
        match reader.next() {
            Ok((offset, block)) => {
                // num_packets += 1;
                match block {
                    PcapBlockOwned::Legacy(packet) => {
                        // println!("{}", packet.data.len());
                        // etherのヘッダ長は14byte
                        let ether_data = &packet.data[14..];
                        // ipv4のヘッダ長は可変(基本20byte)
                        let ip_header_size = ((ether_data[0] & 15) * 4) as usize;
                        let packet_size = (((ether_data[2] as u32) << 8) + ether_data[3] as u32) as usize;
                        let ip_data = &ether_data[ip_header_size..packet_size];
                        // udpのヘッダ長は8byte
                        let udp_data = &ip_data[8..ip_data.len()];
                        parse_packet_body(udp_data, &mut writer);
                    },
                    _ => ()
                }
                reader.consume(offset);
            }
            Err(pcap_parser::PcapError::Eof) => break,
            Err(pcap_parser::PcapError::Incomplete) => {
                reader.refill().unwrap();
            },
            Err(err) => panic!("packet read failed: {:?}", err),
        }

        // frame_count += 1;
        // if frame_count == frames_per_fragment {
        //     writer.finalize();
        //     stream.add(PcdFragment { 
        //         vertices: writer.buffer.clone(), 
        //         frame_start_indices: writer.frame_start_indices.clone(),
        //         max_point_num: writer.max_point_num
        //     });
        //     writer = VertexWriter::create();
        //     frame_count = 0;
        // }
    }
    writer.finalize();
    // if frame_count > 0 {
    //     writer.finalize();
    //     stream.add(PcdFragment { 
    //         vertices: writer.buffer.clone(), 
    //         frame_start_indices: writer.frame_start_indices.clone(),
    //         max_point_num: writer.max_point_num
    //     });
    // }
    println!("elapsed in rust: {} ms", start.elapsed().as_millis());
}

pub fn capture_hesai(stream: StreamSink<PcdFrame>, address: String) {
    // println!("Hello, world!");
    let socket = UdpSocket::bind(address).expect("Failed to bind socket");
    socket.set_read_timeout(Some(Duration::from_millis(100))).unwrap();
    let mut buf = [0; 1500];

    // let mut frame_counter = 0;
    // let mut invalid_point_num = 0;

    let mut writer = VertexWriter::create(stream);

    loop {
        match socket.recv_from(&mut buf) {
            Ok((amt, _src)) => {
                // println!("recv_from function succeeded: {} bytes read from {}", amt, src);
                parse_packet_body(&buf[..amt], &mut writer);
                // invalid_point_num += points.iter().filter(|p| p.distance_m < 0.05).count();
                // frame_counter += 1;
                // if frame_counter >= 500 {
                //     println!("{}", invalid_point_num);
                //     invalid_point_num = 0;
                //     frame_counter = 0;
                // }
            }
            Err(e) => {
                println!("recv_from function failed: {}", e);
                break;
            }
        }
    }
}

pub struct SolidAngleImageConfig {
    pub azi_start: f32,
    pub azi_end: f32,
    pub azi_step: f32,
    pub alt_start: f32,
    pub alt_end: f32,
    pub alt_step: f32,
}

struct SolidAngleStepper {
    start: f32,
    end: f32,
    step: f32,
    length: usize,
}

impl SolidAngleStepper {
    fn new(start: f32, end: f32, step: f32) -> Self {
        let factor = (end - start) / step;
        let calibrated_end = start + step * factor.floor();
        let length = ((calibrated_end - start) / step).floor() as usize;
        Self {
            start,
            end: calibrated_end,
            step,
            length
        }
    }

    fn to_index(&self, value: f32) -> Option<usize> {
        if self.step > 0.0 && (value < self.start || value >= self.end) {
            return None;
        }
        if self.step < 0.0 && (value > self.start || value <= self.end) {
            return None;
        }
        Some(((value - self.start) / self.step) as usize)
    }

    fn to_label(&self, value: usize) -> f32 {
        self.start + self.step * value as f32
    }
}

// generate bmp image
pub fn generate_solid_angle_image(other_data: Vec<f32>, mask: Vec<f32>, config: SolidAngleImageConfig) -> Vec<u8> {
    let azi_stepper = SolidAngleStepper::new(config.azi_start, config.azi_end, config.azi_step);
    let alt_stepper = SolidAngleStepper::new(config.alt_start, config.alt_end, config.alt_step);

    let mut removed_count = vec![0; azi_stepper.length * alt_stepper.length];
    let mut all_count = vec![0; azi_stepper.length * alt_stepper.length];
    for i in 0..other_data.len() / 6 {
        let azi = other_data[i * 6 + 2];
        let alt = other_data[i * 6 + 5];
        let azi_index = azi_stepper.to_index(azi);
        let alt_index = alt_stepper.to_index(alt);
        if azi_index.is_none() || alt_index.is_none() {
            continue;
        }
        let azi_index = azi_index.unwrap();
        let alt_index = alt_index.unwrap();
        
        let index = azi_index + alt_index * azi_stepper.length;
        all_count[index] += 1;
        if mask[i] < 0.5 {
            removed_count[index] += 1;
        }
    }

    let mut image = image::RgbImage::new(azi_stepper.length as u32, alt_stepper.length as u32);
    let colormap = colorgrad::viridis();
    for (x, y, pixel) in image.enumerate_pixels_mut() {
        let index = x as usize + y as usize * azi_stepper.length;
        let ratio = removed_count[index] as f64 / all_count[index] as f64;
        let color = colormap.at(ratio);
        *pixel = image::Rgb([(color.r * 255.0) as u8, (color.g * 255.0) as u8, (color.b * 255.0) as u8]);
    }
    let mut bytes: Vec<u8> = Vec::new();
    image.write_to(&mut Cursor::new(&mut bytes), image::ImageOutputFormat::Bmp).unwrap();
    bytes
}

// #[cfg(test)]
// mod tests {
//     use super::*;

//     #[test]
//     fn test_read_pcap() {
//         let path = String::from("C:\\Users\\hykwy\\flutter_pcd\\2023-03-03-1.pcap");
//         let pcd_video = read_pcap(path);
//         println!("max_point_num: {}", pcd_video.max_point_num);
//         println!("vertices: {}", pcd_video.vertices.len());
//     }
// }