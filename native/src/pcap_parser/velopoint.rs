#[derive(Debug, Clone, Copy)]
pub struct VeloPoint {
    pub reflectivity: u8,
    pub channel: u8,
    pub azimuth: u16,
    pub distance_m: f32,
    pub timestamp: u32,
    pub vertical_angle: f32,
    pub x: f32,
    pub y: f32,
    pub z: f32,
}
