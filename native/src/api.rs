use std::fs::File;
use pcap_parser::*;
use pcap_parser::traits::PcapReaderIterator;
use crate::pcap_parser::framewriter::FrameWriter;
use crate::pcap_parser::vertexwriter::VertexWriter;

use super::pcap_parser::parse_packet_body;

pub struct PcdVideo {
    pub vertices: Vec<f32>,
    pub frame_start_indices: Vec<u32>,
    pub max_point_num: u32,
}

pub fn read_pcap(path: String) -> PcdVideo {
    let start = std::time::Instant::now();
    let file = File::open(path).unwrap();
    let mut reader = LegacyPcapReader::new(65536, file).unwrap();

    let mut writer = VertexWriter::create();
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
    }
    writer.finalize();

    println!("elapsed in rust: {} ms", start.elapsed().as_millis());

    PcdVideo { 
        vertices: writer.buffer, 
        frame_start_indices: writer.frame_start_indices,
        max_point_num: writer.max_point_num
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_read_pcap() {
        let path = String::from("C:\\Users\\hykwy\\flutter_pcd\\2023-03-03-1.pcap");
        let pcd_video = read_pcap(path);
        println!("max_point_num: {}", pcd_video.max_point_num);
        println!("vertices: {}", pcd_video.vertices.len());
    }
}