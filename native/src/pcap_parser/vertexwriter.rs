use crate::api::PcdFrame;

use super::{framewriter::FrameWriter, velopoint::VeloPoint};
use colorgrad;
use flutter_rust_bridge::StreamSink;

pub struct VertexWriter {
    pub buffer: Vec<f32>,
    pub points: Vec<f32>,
    previous_azimuth: u16,
    colormap: colorgrad::Gradient,
    stream: StreamSink<PcdFrame>,
}

impl VertexWriter {
    pub fn create(stream: StreamSink<PcdFrame>) -> Self {
        let colormap = colorgrad::turbo();
        Self {
            buffer: Vec::new(),
            points: Vec::new(),
            previous_azimuth: 0,
            colormap,
            stream,
        }
    }

    pub fn sink(&mut self) {
        let fragment = PcdFrame {
            vertices: self.buffer.clone(),
            // points: Vec::new(),
            points: self.points.clone(),
        };
        self.stream.add(fragment);
        self.buffer.clear();
        self.points.clear();
    }
}

impl FrameWriter for VertexWriter {
    fn write_row(&mut self, row: VeloPoint) {
        if row.azimuth < self.previous_azimuth {
            if !self.buffer.is_empty() {
                self.sink();
            }
        }
        self.previous_azimuth = row.azimuth;
        let color = self.colormap.at(row.reflectivity as f64 / 255.0);
        let xyzrgb = [
            row.x, row.y, row.z, 
            color.r as f32, color.g as f32, color.b as f32
        ];
        self.buffer.extend(&xyzrgb);
        self.points.extend(&[
            row.reflectivity as f32,
            row.channel as f32,
            row.azimuth as f32,
            row.distance_m,
            row.timestamp as f32,
            row.vertical_angle,
            row.x, row.y, row.z,
        ]);
    }

    fn finalize(&mut self) {
        if !self.buffer.is_empty() {
            self.sink();
        }
    }

    fn write_attribute(&mut self, _laser_num: u32, _motor_speed: u32, _return_mode: u32, _manufacturer: &str, _model: &str) { }
}