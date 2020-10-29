use structopt::StructOpt;
use std::path::PathBuf;
use std::fs::File;
use std::io::{BufWriter, BufReader, BufRead, Read, Write};
use std::collections::HashMap;

#[derive(Debug, StructOpt)]
#[structopt(name = "node renamer")]
struct Opt {
    /// Input file (will not be overwritten)
    #[structopt(parse(from_os_str))]
    input_path: PathBuf, 
    
    /// Output file, defaults to "input file".normalised
    #[structopt(parse(from_os_str))]
    output_path: Option<PathBuf>, 
}

fn map_node_ids(reader: &mut BufReader<impl Read>) -> HashMap<u64, u32> {
    let mut ids = HashMap::new();
    for line in reader.lines()
        .map(|l| l.unwrap())
        .filter(|l| !l.starts_with('#')) {

        let mut elts = line[..].split_whitespace();
        let src: u64 = elts.next().unwrap().parse().ok().expect("malformed src");
        let dst: u64 = elts.next().unwrap().parse().ok().expect("malformed dst");

        ids.insert(src, 0);
        ids.insert(dst, 0);
    }
    ids.iter_mut().enumerate().for_each(|(i,(_k,v))| *v=i as u32);
    ids
}

fn main() -> std::io::Result<()> {
    let Opt{ mut input_path, output_path } = Opt::from_args();

    let f_in = File::open(&input_path)?;
    let f_out = File::open(&output_path.unwrap_or_else(|| {
            input_path.push(".normalised"); input_path
    }))?;
    let mut reader = BufReader::new(f_in);
    let mut writer = BufWriter::new(f_out);

    let ids = map_node_ids(&mut reader);
    for line in reader.lines()
        .map(|l| l.unwrap())
        .filter(|l| !l.starts_with('#')) {

        let mut elts = line[..].split_whitespace();
        let src: u64 = elts.next().unwrap().parse().ok().expect("malformed src");
        let dst: u64 = elts.next().unwrap().parse().ok().expect("malformed dst");
        let weight: &str = elts.next().unwrap();
        
        let renamed_src = ids.get(&src).unwrap();
        let renamed_dst = ids.get(&dst).unwrap();
        writer.write_fmt(format_args!("{} {} {}", renamed_src, renamed_dst, weight)).unwrap();
    }
    Ok(())
}
