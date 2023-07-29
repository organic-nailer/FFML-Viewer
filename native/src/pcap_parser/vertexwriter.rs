use super::{framewriter::FrameWriter, velopoint::VeloPoint};
use std::cmp::max;
use colorgrad;

pub struct VertexWriter {
    pub buffer: Vec<f32>,
    pub frame_start_indices: Vec<u32>,
    pub max_point_num: u32,
    previous_azimuth: u16,
    colormap: colorgrad::Gradient,
}

impl VertexWriter {
    pub fn create() -> Self {
        let colormap = colorgrad::turbo();
        Self {
            buffer: Vec::new(),
            frame_start_indices: Vec::new(),
            max_point_num: 0,
            previous_azimuth: 0,
            colormap,
        }
    }
}

impl FrameWriter for VertexWriter {
    fn write_row(&mut self, row: VeloPoint) {
        if row.azimuth < self.previous_azimuth {
            let point_num_bytes = self.buffer.len() as u32 - self.frame_start_indices.last().unwrap_or(&0);
            if point_num_bytes > 0 {
                self.max_point_num = max(self.max_point_num, point_num_bytes / 6);
                self.frame_start_indices.push(self.buffer.len() as u32);
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
            self.frame_start_indices.push(self.buffer.len() as u32);
        }
    }

    fn write_attribute(&mut self, _laser_num: u32, _motor_speed: u32, _return_mode: u32, _manufacturer: &str, _model: &str) { }
}