var FindProxyForURL = function(init, profiles) {
    return function(url, host) {
        "use strict";
        var result = init, scheme = url.substr(0, url.indexOf(":"));
        do {
            result = profiles[result];
            if (typeof result === "function") result = result(url, host, scheme);
        } while (typeof result !== "string" || result.charCodeAt(0) === 43);
        return result;
    };
}("+Citrix", {
    "+Citrix": function(url, host, scheme) {
        "use strict";
        if (/(?:^|\.)citrite\.net$/.test(host)) return "+Local SOCKS";
        if (/(?:^|\.)uk\.xensource\.com$/.test(host)) return "+Local SOCKS";
        if (/(?:^|\.)backstage.citrix.com$/.test(host)) return "+Local SOCKS";
        if (/(?:^|\.)identity.citrix.com$/.test(host)) return "+Local SOCKS";
        return "DIRECT";
    },
    "+Local SOCKS": function(url, host, scheme) {
        "use strict";
        if (host === "[::1]" || host === "localhost" || host === "127.0.0.1") return "DIRECT";
        return "SOCKS5 localhost:1080; SOCKS localhost:1080";
    }
});
