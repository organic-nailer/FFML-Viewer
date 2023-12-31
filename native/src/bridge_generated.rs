#![allow(
    non_camel_case_types,
    unused,
    clippy::redundant_closure,
    clippy::useless_conversion,
    clippy::unit_arg,
    clippy::double_parens,
    non_snake_case,
    clippy::too_many_arguments
)]
// AUTO GENERATED FILE, DO NOT EDIT.
// Generated by `flutter_rust_bridge`@ 1.79.0.

use crate::api::*;
use core::panic::UnwindSafe;
use flutter_rust_bridge::rust2dart::IntoIntoDart;
use flutter_rust_bridge::*;
use std::ffi::c_void;
use std::sync::Arc;

// Section: imports

// Section: wire functions

fn wire_read_pcap_stream_impl(port_: MessagePort, path: impl Wire2Api<String> + UnwindSafe) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap::<_, _, _, ()>(
        WrapInfo {
            debug_name: "read_pcap_stream",
            port: Some(port_),
            mode: FfiCallMode::Stream,
        },
        move || {
            let api_path = path.wire2api();
            move |task_callback| {
                Ok(read_pcap_stream(
                    task_callback.stream_sink::<_, PcdFrame>(),
                    api_path,
                ))
            }
        },
    )
}
fn wire_capture_hesai_impl(port_: MessagePort, address: impl Wire2Api<String> + UnwindSafe) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap::<_, _, _, ()>(
        WrapInfo {
            debug_name: "capture_hesai",
            port: Some(port_),
            mode: FfiCallMode::Stream,
        },
        move || {
            let api_address = address.wire2api();
            move |task_callback| {
                Ok(capture_hesai(
                    task_callback.stream_sink::<_, PcdFrame>(),
                    api_address,
                ))
            }
        },
    )
}
fn wire_generate_solid_angle_image_impl(
    port_: MessagePort,
    other_data: impl Wire2Api<Vec<f32>> + UnwindSafe,
    mask: impl Wire2Api<Vec<f32>> + UnwindSafe,
    config: impl Wire2Api<SolidAngleImageConfig> + UnwindSafe,
) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap::<_, _, _, Vec<u8>>(
        WrapInfo {
            debug_name: "generate_solid_angle_image",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || {
            let api_other_data = other_data.wire2api();
            let api_mask = mask.wire2api();
            let api_config = config.wire2api();
            move |task_callback| {
                Ok(generate_solid_angle_image(
                    api_other_data,
                    api_mask,
                    api_config,
                ))
            }
        },
    )
}
// Section: wrapper structs

// Section: static checks

// Section: allocate functions

// Section: related functions

// Section: impl Wire2Api

pub trait Wire2Api<T> {
    fn wire2api(self) -> T;
}

impl<T, S> Wire2Api<Option<T>> for *mut S
where
    *mut S: Wire2Api<T>,
{
    fn wire2api(self) -> Option<T> {
        (!self.is_null()).then(|| self.wire2api())
    }
}

impl Wire2Api<f32> for f32 {
    fn wire2api(self) -> f32 {
        self
    }
}

impl Wire2Api<u8> for u8 {
    fn wire2api(self) -> u8 {
        self
    }
}

// Section: impl IntoDart

impl support::IntoDart for PcdFrame {
    fn into_dart(self) -> support::DartAbi {
        vec![
            self.vertices.into_into_dart().into_dart(),
            self.colors.into_into_dart().into_dart(),
            self.other_data.into_into_dart().into_dart(),
        ]
        .into_dart()
    }
}
impl support::IntoDartExceptPrimitive for PcdFrame {}
impl rust2dart::IntoIntoDart<PcdFrame> for PcdFrame {
    fn into_into_dart(self) -> Self {
        self
    }
}

// Section: executor

support::lazy_static! {
    pub static ref FLUTTER_RUST_BRIDGE_HANDLER: support::DefaultHandler = Default::default();
}

#[cfg(not(target_family = "wasm"))]
#[path = "bridge_generated.io.rs"]
mod io;
#[cfg(not(target_family = "wasm"))]
pub use io::*;
