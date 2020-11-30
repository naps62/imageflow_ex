extern crate imageflow_core;

use crate::atoms;
use rustler::{Binary, Encoder, Env, Error, Term};
use std::sync::{Arc, Mutex, MutexGuard};

use imageflow_core::{Context, JsonResponse};

struct Job {
    pub inner: Arc<Mutex<Box<Context>>>,
}

impl Job {
    pub fn create() -> Result<usize, imageflow_core::FlowError> {
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

    pub fn add_input(&self, io_id: i32, bytes: &[u8]) {
        let mut ctx = self.inner.lock().unwrap();
        ctx.add_copied_input_buffer(io_id, bytes).unwrap();
    }

    pub fn message(&self, method: &String, message: &String) -> Result<JsonResponse, JsonResponse> {
        let mut ctx = self.inner.lock().unwrap();

        match ctx.message(&method, message.as_bytes()) {
            (resp, Ok(_)) => Ok(resp),
            (resp, Err(_)) => Err(resp),
        }
    }

    pub fn load_from_id<'a>(id_term: Term<'a>) -> Result<&mut Job, Error> {
        let id: usize = id_term.decode()?;
        let ptr = id as *mut Job;

        if ptr.is_null() {
            eprintln!("Null context pointer provided. Terminating process.",);
            ::std::process::abort();
        }

        let job = unsafe { &mut *ptr };

        Ok(job)
    }

    fn destroy_from_id(id_term: Term) -> Result<(), Error> {
        let id: usize = id_term.decode()?;
        let ptr = id as *mut Job;

        unsafe { Box::from_raw(ptr) };

        Ok(())
    }
}

pub fn create<'a>(env: Env<'a>, _args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    match Job::create() {
        Ok(id) => Ok((atoms::ok(), id).encode(env)),
        Err(_e) => Err(rustler::Error::Atom("Unable to create context")),
    }
}

pub fn destroy<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    Job::destroy_from_id(args[0]).ok().unwrap();
    // let id: usize = args[0].decode()?;
    // let ptr = id as *mut Job;

    // unsafe { Box::from_raw(ptr) };
    // let job = Job::load_from_id(args[0]).ok().unwrap();

    // job.destroy().unwrap();

    Ok(atoms::ok().encode(env))
}

pub fn add_input<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let job = Job::load_from_id(args[0]).ok().unwrap();

    let io_id: i32 = args[1].decode()?;
    let bytes: Binary = args[2].decode()?;

    job.add_input(io_id, bytes.as_slice());

    Ok(atoms::ok().encode(env))
}

pub fn get_output<'a>(_env: Env<'a>, _args: &[Term<'a>]) {}

pub fn message<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let job = Job::load_from_id(args[0]).ok().unwrap();

    let method: String = args[1].decode()?;
    let message: String = args[2].decode()?;

    let ret = match job.message(&method, &message) {
        Ok(resp) => (atoms::ok(), resp.response_json.encode(env)),
        Err(resp) => (atoms::error(), resp.response_json.encode(env)),
    };

    Ok(ret.encode(env))
}
