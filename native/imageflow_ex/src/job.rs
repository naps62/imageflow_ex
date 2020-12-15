extern crate imageflow_core;

use std::panic::{catch_unwind, AssertUnwindSafe};
use std::sync::{Arc, Mutex};

use imageflow_core::{Context, FlowError, JsonResponse};
use imageflow_types::IoDirection;

pub struct Job {
    pub inner: Arc<Mutex<Box<Context>>>,
}

macro_rules! context_ready {
    ($self:ident) => {{
        let ctx = $self.inner.lock().unwrap();

        if ctx.outward_error().has_error() {
            return Err(format!(
                "The context passed is in an error state and cannot be used.\n{}",
                ctx.outward_error()
            ));
        }

        ctx
    }};
}

macro_rules! handle_result {
    ($ctx:ident, $result:expr) => {{
        match $result {
            Ok(Ok(v)) => Ok(v),
            Ok(Err(error)) => {
                let msg = format!("{}", error.message);
                $ctx.outward_error_mut().try_set_error(error);
                Err(msg)
            }
            Err(error) => {
                $ctx.outward_error_mut().try_set_panic_error(error);
                Err(format!("{}", $ctx.outward_error()))
            }
        }
    }};
}

impl Job {
    pub fn create() -> Result<usize, FlowError> {
        match Context::create_cant_panic() {
            Ok(context) => {
                let job = Job {
                    inner: Arc::new(Mutex::new(context)),
                };
                let re = Box::into_raw(Box::new(job));
                Ok(re as usize)
            }
            Err(e) => Err(e),
        }
    }

    pub fn add_input_buffer(&self, io_id: i32, bytes: &[u8]) -> Result<(), String> {
        let mut ctx = context_ready!(self);

        let result = catch_unwind(AssertUnwindSafe(|| {
            ctx.add_copied_input_buffer(io_id, bytes)
        }));

        handle_result!(ctx, result)
    }

    pub fn add_input_file(&self, io_id: i32, path: &String) -> Result<(), String> {
        let mut ctx = context_ready!(self);

        let result = catch_unwind(AssertUnwindSafe(|| {
            ctx.add_file(io_id, IoDirection::In, path.as_str())
        }));

        handle_result!(ctx, result)
    }

    pub fn add_output_buffer(&self, io_id: i32) -> Result<(), String> {
        let mut ctx = context_ready!(self);

        let result = catch_unwind(AssertUnwindSafe(|| ctx.add_output_buffer(io_id)));

        handle_result!(ctx, result)
    }

    pub fn message(&self, method: &String, message: &String) -> Result<JsonResponse, String> {
        let mut ctx = self.inner.lock().unwrap();

        let result = catch_unwind(AssertUnwindSafe(|| {
            match ctx.message(&method, message.as_bytes()) {
                (resp, Ok(_)) => Ok(resp),
                (_, Err(error)) => Err(error),
            }
        }));

        handle_result!(ctx, result)
    }

    pub fn get_output_buffer<'a>(&'a self, io_id: i32) -> Result<Vec<u8>, String> {
        let mut ctx = self.inner.lock().unwrap();

        let result = catch_unwind(AssertUnwindSafe(|| {
            ctx.get_output_buffer_slice(io_id).map(|v| v.to_vec())
        }));

        handle_result!(ctx, result)
    }

    pub fn save_output_to_file(&self, io_id: i32, path: &String) -> std::io::Result<()> {
        use std::fs::File;
        use std::io::prelude::*;
        use std::io::{Error, ErrorKind};

        let mut ctx = self.inner.lock().unwrap();

        let result = catch_unwind(AssertUnwindSafe(|| ctx.get_output_buffer_slice(io_id)));

        match handle_result!(ctx, result) {
            Ok(buffer) => {
                let mut file = File::create(path)?;

                file.write_all(buffer)?;

                Ok(())
            }
            Err(e) => Err(Error::new(ErrorKind::Other, e)),
        }
    }

    pub fn load_from_id<'a>(id: usize) -> Result<&'a mut Job, ()> {
        let ptr = id as *mut Job;

        if ptr.is_null() {
            eprintln!("Null context pointer provided. Terminating process.",);
            ::std::process::abort();
        }

        let job = unsafe { &mut *ptr };

        Ok(job)
    }

    pub fn destroy_from_id(id: usize) -> Result<(), ()> {
        let ptr = id as *mut Job;

        unsafe { Box::from_raw(ptr) };

        Ok(())
    }
}
