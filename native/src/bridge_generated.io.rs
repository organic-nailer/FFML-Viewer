use super::*;
// Section: wire functions

#[no_mangle]
pub extern "C" fn wire_read_pcap_stream(port_: i64, path: *mut wire_uint_8_list) {
    wire_read_pcap_stream_impl(port_, path)
}

#[no_mangle]
pub extern "C" fn wire_capture_hesai(port_: i64, address: *mut wire_uint_8_list) {
    wire_capture_hesai_impl(port_, address)
}

#[no_mangle]
pub extern "C" fn wire_generate_solid_angle_image(
    port_: i64,
    other_data: *mut wire_float_32_list,
    mask: *mut wire_float_32_list,
    config: *mut wire_SolidAngleImageConfig,
) {
    wire_generate_solid_angle_image_impl(port_, other_data, mask, config)
}

// Section: allocate functions

#[no_mangle]
pub extern "C" fn new_box_autoadd_solid_angle_image_config_0() -> *mut wire_SolidAngleImageConfig {
    support::new_leak_box_ptr(wire_SolidAngleImageConfig::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_float_32_list_0(len: i32) -> *mut wire_float_32_list {
    let ans = wire_float_32_list {
        ptr: support::new_leak_vec_ptr(Default::default(), len),
        len,
    };
    support::new_leak_box_ptr(ans)
}

#[no_mangle]
pub extern "C" fn new_uint_8_list_0(len: i32) -> *mut wire_uint_8_list {
    let ans = wire_uint_8_list {
        ptr: support::new_leak_vec_ptr(Default::default(), len),
        len,
    };
    support::new_leak_box_ptr(ans)
}

// Section: related functions

// Section: impl Wire2Api

impl Wire2Api<String> for *mut wire_uint_8_list {
    fn wire2api(self) -> String {
        let vec: Vec<u8> = self.wire2api();
        String::from_utf8_lossy(&vec).into_owned()
    }
}
impl Wire2Api<SolidAngleImageConfig> for *mut wire_SolidAngleImageConfig {
    fn wire2api(self) -> SolidAngleImageConfig {
        let wrap = unsafe { support::box_from_leak_ptr(self) };
        Wire2Api::<SolidAngleImageConfig>::wire2api(*wrap).into()
    }
}

impl Wire2Api<Vec<f32>> for *mut wire_float_32_list {
    fn wire2api(self) -> Vec<f32> {
        unsafe {
            let wrap = support::box_from_leak_ptr(self);
            support::vec_from_leak_ptr(wrap.ptr, wrap.len)
        }
    }
}
impl Wire2Api<SolidAngleImageConfig> for wire_SolidAngleImageConfig {
    fn wire2api(self) -> SolidAngleImageConfig {
        SolidAngleImageConfig {
            azi_start: self.azi_start.wire2api(),
            azi_end: self.azi_end.wire2api(),
            azi_step: self.azi_step.wire2api(),
            alt_start: self.alt_start.wire2api(),
            alt_end: self.alt_end.wire2api(),
            alt_step: self.alt_step.wire2api(),
        }
    }
}

impl Wire2Api<Vec<u8>> for *mut wire_uint_8_list {
    fn wire2api(self) -> Vec<u8> {
        unsafe {
            let wrap = support::box_from_leak_ptr(self);
            support::vec_from_leak_ptr(wrap.ptr, wrap.len)
        }
    }
}
// Section: wire structs

#[repr(C)]
#[derive(Clone)]
pub struct wire_float_32_list {
    ptr: *mut f32,
    len: i32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_SolidAngleImageConfig {
    azi_start: f32,
    azi_end: f32,
    azi_step: f32,
    alt_start: f32,
    alt_end: f32,
    alt_step: f32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_uint_8_list {
    ptr: *mut u8,
    len: i32,
}

// Section: impl NewWithNullPtr

pub trait NewWithNullPtr {
    fn new_with_null_ptr() -> Self;
}

impl<T> NewWithNullPtr for *mut T {
    fn new_with_null_ptr() -> Self {
        std::ptr::null_mut()
    }
}

impl NewWithNullPtr for wire_SolidAngleImageConfig {
    fn new_with_null_ptr() -> Self {
        Self {
            azi_start: Default::default(),
            azi_end: Default::default(),
            azi_step: Default::default(),
            alt_start: Default::default(),
            alt_end: Default::default(),
            alt_step: Default::default(),
        }
    }
}

impl Default for wire_SolidAngleImageConfig {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

// Section: sync execution mode utility

#[no_mangle]
pub extern "C" fn free_WireSyncReturn(ptr: support::WireSyncReturn) {
    unsafe {
        let _ = support::box_from_leak_ptr(ptr);
    };
}
