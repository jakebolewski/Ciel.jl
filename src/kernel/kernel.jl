import Base: Random

import ZMQ
import JSON

include("heartbeat.jl")

type Kernel
    ctx::ZMQ.Context
    publish::ZMQ.Socket{ZMQ.PUB}
    rawinput::ZMQ.Socket{ZMQ.ROUTER}
    requests::ZMQ.Socket{ZMQ.ROUTER}
    control::ZMQ.Socket{ZMQ.ROUTER}
    heartbeat::ZMQ.Socket{ZMQ.REP}
end

default_profile() = begin
    port0 = 5678
    profile = (String=>Any)[
        "ip" => "127.0.0.1",
        "transport"  => "tcp",
        "stdin_port"   => port0,
        "control_port" => port0 + 1,
        "hb_port"      => port0 + 2,
        "shell_port"   => port0 + 3,
        "iopub_port"   => port0 + 4,
        "key" => Random.uuid4()
    ]
    return profile
end

Kernel(profile) = begin
    
    ctx = ZMQ.Context()
    publish   = ZMQ.Socket(ctx, ZMQ.PUB)
    rawinput  = ZMQ.Socket(ctx, ZMQ.ROUTER)
    requests  = ZMQ.Socket(ctx, ZMQ.ROUTER)
    control   = ZMQ.Socket(ctx, ZMQ.ROUTER)
    heartbeat = ZMQ.Socket(ctx, ZMQ.REP)
    
    ZMQ.bind(publish, 
        "$(profile["transport"])://$(profile["ip"]):$(profile["iopub_port"])")
    ZMQ.bind(requests,
        "$(profile["transport"])://$(profile["ip"]):$(profile["shell_port"])")
    ZMQ.bind(control, 
        "$(profile["transport"])://$(profile["ip"]):$(profile["control_port"])")
    ZMQ.bind(rawinput,
        "$(profile["transport"])://$(profile["ip"]):$(profile["stdin_port"])")
    ZMQ.bind(heartbeat, 
        "$(profile["transport"])://$(profile["ip"]):$(profile["hb_port"])")

    start_heartbeat!(heartbeat)

    # bind sockets to transports
    return Kernel(ctx, publish, rawinput, requests, control, heartbeat) 
end

Base.show(io::IO, k::Kernel) = begin
    print(io, "Kernel(\n")
    for name in names(k)
        print(io, string("  ", "$name: ", getfield(k, name), ",\n"))
    end
    print(io, ")\n")
end


test() = begin
    Kernel(default_profile())
end

test()
