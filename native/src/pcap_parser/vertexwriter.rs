use crate::api::PcdFragment;

use super::{framewriter::FrameWriter, velopoint::VeloPoint};
use std::cmp::max;
use colorgrad;
use flutter_rust_bridge::StreamSink;

pub struct VertexWriter {
    pub buffer: Vec<f32>,
    pub frame_start_indices: Vec<u32>,
    pub max_point_num: u32,
    previous_azimuth: u16,
    colormap: colorgrad::Gradient,
    frames_per_fragment: u32,
    stream: StreamSink<PcdFragment>,
}

impl VertexWriter {
    pub fn create(frames_per_fragment: u32, stream: StreamSink<PcdFragment>) -> Self {
        let colormap = colorgrad::turbo();
        Self {
            buffer: Vec::new(),
            frame_start_indices: vec![0],
            max_point_num: 0,
            previous_azimuth: 0,
            colormap,
            frames_per_fragment,
            stream,
        }
    }

    pub fn sink(&mut self) {
        let fragment = PcdFragment {
            vertices: self.buffer.clone(),
            frame_start_indices: self.frame_start_indices.clone(),
            max_point_num: self.max_point_num,
        };
        self.stream.add(fragment);
        self.buffer.clear();
        self.frame_start_indices.clear();
        self.frame_start_indices.push(0);
        self.max_point_num = 0;
    }
}

impl FrameWriter for VertexWriter {
    fn write_row(&mut self, row: VeloPoint) {
        if row.azimuth < self.previous_azimuth {
            let point_num_bytes = self.buffer.len() as u32 - self.frame_start_indices.last().unwrap_or(&0);
            if point_num_bytes > 0 {
                self.max_point_num = max(self.max_point_num, point_num_bytes / 6);
                if self.frame_start_indices.len() as u32 == self.frames_per_fragment {
                    self.sink();
                }
                else {
                    self.frame_start_indices.push(self.buffer.len() as u32);
                }
            }
        }
        self.previous_azimuth = row.azimuth;
        let color = self.colormap.at(row.reflectivity as f64 / 255.0);
        let xyzrgb = [
            row.x, row.y, row.z, 
            color.r as f32, color.g as f32, color.b as f32
        ];
        self.buffer.extend(&xyzrgb);
    }

    fn finalize(&mut self) {
        let point_num_bytes = self.buffer.len() as u32 - self.frame_start_indices.last().unwrap_or(&0);
        if point_num_bytes > 0 {
            self.max_point_num = max(self.max_point_num, point_num_bytes / 6);
            // self.frame_start_indices.push(self.buffer.len() as u32);
            self.sink();
        }
    }

    fn write_attribute(&mut self, _laser_num: u32, _motor_speed: u32, _return_mode: u32, _manufacturer: &str, _model: &str) { }
}