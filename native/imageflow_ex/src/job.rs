extern crate imageflow_core;

use crate::atoms;
use rustler::{Binary, Encoder, Env, Error, Term};
use std::sync::Mutex;

use imageflow_core::Context;

struct Job {
    pub inner: Mutex<Box<Context>>,
}

macro_rules! context {
    ($ptr:ident) => {{
        if $ptr.is_null() {
            eprintln!("Null context pointer provided. Terminating process.",);
            ::std::process::abort();
        }
        unsafe { ({ &mut *$ptr }) }
    }};
}

pub fn create<'a>(env: Env<'a>, _args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    match Context::create_can_panic() {
        Ok(context) => {
            let job = Job {
                inner: Mutex::new(context),
            };
            let re = Box::into_raw(Box::new(job));

            Ok((atoms::ok(), re as usize).encode(env))
        }

        Err(_e) => Err(rustler::Error::Atom("Unable to create context")),
    }
}

pub fn destroy<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    // let id: usize = args[0].decode()?;
    // let ptr = id as *mut Job;

    // let mut context = context!(ptr).inner.lock().unwrap();

    // context.destroy().unwrap();

    Ok(atoms::ok().encode(env))
}

pub fn add_input<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let id: usize = args[0].decode()?;
    let ptr = id as *mut Job;

    let io_id: i32 = args[1].decode()?;
    let bytes: Binary = args[2].decode()?;

    let mut v = vec![0; 67];
    v.copy_from_slice(bytes.as_slice());

    let mut context = context!(ptr).inner.lock().unwrap();
    context
        .add_copied_input_buffer(io_id, v.as_slice())
        .unwrap();

    Ok(atoms::ok().encode(env))
}

pub fn get_output<'a>(_env: Env<'a>, _args: &[Term<'a>]) {}

pub fn message<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let id: usize = args[0].decode()?;
    let ptr = id as *mut Job;

    let method: String = args[1].decode()?;
    let message: String = args[2].decode()?;

    let mut context = context!(ptr).inner.lock().unwrap();

    match context.message(&method, message.as_bytes()) {
        (resp, Ok(_)) => Ok((atoms::ok(), resp.response_json.encode(env)).encode(env)),
        (r, Err(_)) => panic!(),
    }
}
