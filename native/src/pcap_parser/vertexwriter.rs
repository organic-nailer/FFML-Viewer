use super::{framewriter::FrameWriter, velopoint::VeloPoint};
use std::cmp::max;
use colorgrad;

pub struct VertexWriter {
    pub result: Vec<(Vec<f32>, Vec<f32>)>,
    pub current_vertices: Vec<f32>,
    pub current_colors: Vec<f32>,
    pub max_point_num: usize,
    previous_azimuth: u16,
    colormap: colorgrad::Gradient,
}

impl VertexWriter {
    pub fn create() -> Self {
        let colormap = colorgrad::turbo();
        Self {
            result: vec![],
            current_vertices: vec![],
            current_colors: vec![],
            max_point_num: 0,
            previous_azimuth: 0,
            colormap,
        }
    }
}

impl FrameWriter for VertexWriter {
    fn write_row(&mut self, row: VeloPoint) {
        if row.azimuth < self.previous_azimuth {
            if !self.current_vertices.is_empty() {
                self.max_point_num = max(self.max_point_num, self.current_vertices.len() / 3);
                self.result.push(
                    (self.current_vertices.clone(), self.current_colors.clone())
                );
                self.current_vertices.clear();
                self.current_colors.clear();
            }
        }
        self.previous_azimuth = row.azimuth;
        self.current_vertices.extend(&[row.x, row.y, row.z]);
        let color = self.colormap.at(row.reflectivity as f64 / 255.0);
        self.current_colors.extend(&[color.r as f32, color.g as f32, color.b as f32]);
    }

    fn finalize(&mut self) { }

    fn write_attribute(&mut self, _laser_num: u32, _motor_speed: u32, _return_mode: u32, _manufacturer: &str, _model: &str) { }
}