extern crate imageflow_core;

use std::sync::{Arc, Mutex};

use imageflow_core::{Context, FlowError, JsonResponse};
use imageflow_types::IoDirection;

pub struct Job {
    pub inner: Arc<Mutex<Box<Context>>>,
}

impl Job {
    pub fn create() -> Result<usize, FlowError> {
        match Context::create_can_panic() {
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

    pub fn add_input_buffer(&self, io_id: i32, bytes: &[u8]) {
        let mut ctx = self.inner.lock().unwrap();
        ctx.add_copied_input_buffer(io_id, bytes).unwrap();
    }

    pub fn add_input_file(&self, io_id: i32, path: &String) {
        let mut ctx = self.inner.lock().unwrap();
        ctx.add_file(io_id, IoDirection::In, path.as_str()).unwrap();
    }

    pub fn add_output_buffer(&self, io_id: i32) {
        let mut ctx = self.inner.lock().unwrap();
        ctx.add_output_buffer(io_id);
        // ctx.add_file(io_id, IoDirection::In, path.as_str()).unwrap();
    }

    pub fn message(&self, method: &String, message: &String) -> Result<JsonResponse, JsonResponse> {
        let mut ctx = self.inner.lock().unwrap();

        match ctx.message(&method, message.as_bytes()) {
            (resp, Ok(_)) => Ok(resp),
            (resp, Err(_)) => Err(resp),
        }
    }

    pub fn get_output_buffer(&self, io_id: i32) -> Result<(), FlowError> {
        let mut ctx = self.inner.lock().unwrap();

        let buffer = ctx.get_output_buffer_slice(io_id).unwrap();

        println!("{:?}", buffer);
        Ok(())
    }

    pub fn save_output_to_file(&self, io_id: i32, path: &String) -> std::io::Result<()> {
        use std::fs::File;
        use std::io::prelude::*;

        let ctx = self.inner.lock().unwrap();

        let buffer = ctx.get_output_buffer_slice(io_id).unwrap();

        let mut file = File::create(path)?;

        file.write_all(buffer)?;

        Ok(())

        // match ctx.message(&method, message.as_bytes()) {
        //     (resp, Ok(_)) => Ok(resp),
        //     (resp, Err(_)) => Err(resp),
        // }
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
