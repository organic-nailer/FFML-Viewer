use crate::api::PcdFrame;

use super::{framewriter::FrameWriter, velopoint::VeloPoint};
use colorgrad;
use flutter_rust_bridge::StreamSink;

pub struct VertexWriter {
    pub vertices: Vec<f32>,
    pub colors: Vec<f32>,
    pub othre_data: Vec<f32>,
    previous_azimuth: u16,
    colormap: colorgrad::Gradient,
    stream: StreamSink<PcdFrame>,
}

impl VertexWriter {
    pub fn create(stream: StreamSink<PcdFrame>) -> Self {
        let colormap = colorgrad::turbo();
        Self {
            vertices: Vec::new(),
            colors: Vec::new(),
            othre_data: Vec::new(),
            previous_azimuth: 0,
            colormap,
            stream,
        }
    }

    pub fn sink(&mut self) {
        let fragment = PcdFrame {
            vertices: self.vertices.clone(),
            colors: self.colors.clone(),
            other_data: self.othre_data.clone(),
        };
        self.stream.add(fragment);
        self.vertices.clear();
        self.colors.clear();
        self.othre_data.clear();
    }
}

impl FrameWriter for VertexWriter {
    fn write_row(&mut self, row: VeloPoint) {
        if row.azimuth < self.previous_azimuth {
            if !self.vertices.is_empty() {
                self.sink();
            }
        }
        self.previous_azimuth = row.azimuth;
        let color = self.colormap.at(row.reflectivity as f64 / 255.0);
        self.vertices.extend(&[row.x,row.y,row.z]);
        self.colors.extend(&[color.r as f32, color.g as f32, color.b as f32]);
        self.othre_data.extend(&[
            row.reflectivity as f32,
            row.channel as f32,
            row.azimuth as f32,
            row.distance_m,
            row.timestamp as f32,
            row.vertical_angle,
        ]);
    }

    fn finalize(&mut self) {
        if !self.vertices.is_empty() {
            self.sink();
        }
    }

    fn write_attribute(&mut self, _laser_num: u32, _motor_speed: u32, _return_mode: u32, _manufacturer: &str, _model: &str) { }
}