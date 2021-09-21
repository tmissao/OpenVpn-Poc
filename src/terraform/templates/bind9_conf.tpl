acl trusted {
  ${VNET_ADDRESS};
  ${OPENVPN_ADDRESS};
  localhost;
  localnets;
};

options {
  directory "/var/cache/bind";
  recursion yes;
  allow-query { trusted; };
  forwarders {
    ${AZURE_PRIVATE_DNS_IP};
  };
  forward only;
  dnssec-enable no;
  dnssec-validation no;
  auth-nxdomain no;
  listen-on-v6 { any; };
};