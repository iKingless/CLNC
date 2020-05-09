/*
    普通免流   例子，只需要修改HTTP/HTTPS代理IP跟模式(可作为wap模式)
*/

tcp::Global {
    tcp_listen = 0.0.0.0:6650;
}

//HTTPS模式
httpMod::tunnel {
    del_line = host;
    set_first = "[M] [H] [V]\r\nHost: [H]\r\nProxy-Authorization: Basic dWMxMC43LjE2My4xNDQ6MWY0N2QzZWY1M2IwMzU0NDM0NTFjN2VlNzg3M2ZmMzg=\r\n";
}
//HTTP模式
httpMod::http {
    del_line = host;
    set_first = "[M] http://[H_P][U] [V]\r\nHost: [H_P]\r\nProxy-Authorization: Basic dWMxMC43LjE2My4xNDQ6MWY0N2QzZWY1M2IwMzU0NDM0NTFjN2VlNzg3M2ZmMzg=\r\n";
}

tcpProxy::http_proxy {
    //HTTPS代理地址
    destAddr = 101.71.140.5:8128;
    httpMod = http;
}
tcpProxy::https_proxy {
    //HTTPS代理地址
    destAddr = 101.71.140.5:8128;
    tunnelHttpMod = tunnel;
    tunnel_proxy = on;
}

//ssh端口和ssl端口先建立CONNECT连接
tcpAcl::firstConnect {
    tcpProxy = https_proxy;
    matchMode = firstMatch;
    //如果请求为HTTP请求，则重新建立连接
    reMatch = CONNECT http;
    
    dst_port = 22;
    dst_port = 443;
}
//匹配普通http请求
tcpAcl::http {
    tcpProxy = http_proxy;
    continue: method != IS_NOT_HTTP;
    reg_string != WebSocket;
}
//其他请求使用CONNECT代理
tcpAcl::CONNECT {
    tcpProxy = https_proxy;
    dst_port != 0;
}


dns::Global {
    dns_listen = 0.0.0.0:6653;
    cachePath = dns.cache;
    cacheLimit = 512;
}
dnsAcl {
    httpMod = http;
    //HTTP代理地址
    destAddr = 101.71.140.5:8128;
    header_host = 119.29.29.29;
    query_type = A;
    query_type = AAAA;
}
dnsAcl {
    httpMod = tunnel;
    //HTTP tunnel代理地址
    destAddr = 101.71.140.5:8128;
    //UC的tunnel只支持443端口，所以这里使用opendns的443解析
    header_host = 208.67.222.222:433;
    lookup_mode = tcpDNS;
}

//用于接收socks5请求
socks5::recv_socks5 {
    socks5_listen = 0.0.0.0:1881;
    socks5_dns = 127.0.0.1:6653;
    handshake_timeout = 60;
}
