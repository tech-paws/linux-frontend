cd ../backend
cargo build --release -j12
cp target/release/libbackend.so ../frontend-linux/libs/libbackend.so
