# Schema files based on protocol buffers

## Generate code for lightning wire message

```
$ protoc -I ./proto/ --ln_out=lib --plugin=./bin/protoc-gen-ln ./proto/lightning/wire/lightning_messages/*.proto
```

### Generate code for gRPC

```
$ grpc_tools_ruby_protoc -I ./proto --ruby_out=lib --grpc_out=lib ./proto/lightning/grpc/service.proto
$ grpc_tools_ruby_protoc -I ./proto --ruby_out=lib --grpc_out=lib ./proto/lightning/channel/events.proto
$ grpc_tools_ruby_protoc -I ./proto --ruby_out=lib --grpc_out=lib ./proto/lightning/io/events.proto
$ grpc_tools_ruby_protoc -I ./proto --ruby_out=lib --grpc_out=lib ./proto/lightning/payment/events.proto
$ grpc_tools_ruby_protoc -I ./proto --ruby_out=lib --grpc_out=lib ./proto/lightning/router/events.proto
$ grpc_tools_ruby_protoc -I ./proto --ruby_out=lib --grpc_out=lib ./proto/lightning/router/messages.proto
```

### Generate document for gRPC

```

cd proto
protoc --doc_out=./ --doc_opt=markdown,API.md ./lightning/**/*.proto ./lightning/**/**/*.proto

```

see https://github.com/pseudomuto/protoc-gen-doc for more detail