extern crate imageflow_types;

use rustler::types::atom::ok;

mod job;

mod atoms {
    rustler::atoms! {
        saved,
        create_job_error,
        add_input_buffer_error,
        add_input_file_error,
        add_output_buffer_error,
        save_output_to_file_error,
        failed_destroying_job
    }
}

use job::Job;
use rustler::{Atom, Binary};

rustler::init!(
    "Elixir.Imageflow.NIF",
    [
        get_long_version_string,
        job_create,
        job_destroy,
        job_add_input_buffer,
        job_add_input_file,
        job_add_output_buffer,
        job_get_output_buffer,
        job_save_output_to_file,
        job_message,
    ]
);

macro_rules! job {
    ($id:expr) => {
        Job::load_from_id($id).ok().unwrap()
    };
}

#[rustler::nif]
fn get_long_version_string() -> String {
    imageflow_types::version::one_line_version()
}

#[rustler::nif]
pub fn job_create() -> Result<usize, Atom> {
    match Job::create() {
        Ok(id) => Ok(id),
        Err(_e) => Err(atoms::create_job_error()),
    }
}

#[rustler::nif]
pub fn job_destroy(id: usize) -> Result<Atom, Atom> {
    match Job::destroy_from_id(id) {
        Ok(_) => Ok(ok()),
        Err(_) => Err(atoms::failed_destroying_job()),
    }
}

#[rustler::nif]
pub fn job_add_input_buffer(id: usize, io_id: i32, bytes: Binary) -> Result<(), String> {
    match job!(id).add_input_buffer(io_id, bytes.as_slice()) {
        Ok(_) => Ok(()),
        Err(reason) => {
            println!("Error adding input buffer {:?}", reason);
            Err(reason)
        }
    }
}

#[rustler::nif]
pub fn job_add_input_file(id: usize, io_id: i32, path: String) -> Result<Atom, String> {
    match job!(id).add_input_file(io_id, &path) {
        Ok(_) => Ok(ok()),
        Err(e) => Err(e),
    }
}

#[rustler::nif]
pub fn job_add_output_buffer(id: usize, io_id: i32) -> Result<Atom, String> {
    match job!(id).add_output_buffer(io_id) {
        Ok(_) => Ok(ok()),
        Err(e) => Err(e),
    }
}

#[rustler::nif]
pub fn job_get_output_buffer(id: usize, io_id: i32) -> Result<Vec<u8>, String> {
    job!(id).get_output_buffer(io_id)
}

#[rustler::nif]
pub fn job_save_output_to_file(id: usize, io_id: i32, path: String) -> Result<Atom, Atom> {
    match job!(id).save_output_to_file(io_id, &path) {
        Ok(_) => Ok(atoms::saved()),
        Err(reason) => {
            println!("Error saving output to file {:?}", reason);
            Err(atoms::save_output_to_file_error())
        }
    }
}

#[rustler::nif]
pub fn job_message(id: usize, method: String, message: String) -> Result<String, String> {
    match job!(id).message(&method, &message) {
        Ok(resp) => Ok(String::from_utf8_lossy(&resp.response_json).to_string()),
        Err(msg) => Err(msg),
    }
}
