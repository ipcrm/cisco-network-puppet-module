# rubocop:disable Style/FileName
###############################################################################
# Copyright (c) 2014-2016 Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################
#
# See README-develop-beaker-scripts.md (Section: Test Script Variable Reference)
# for information regarding:
#  - test script general prequisites
#  - command return codes
#  - A description of the 'tests' hash and its usage
#
###############################################################################
#
# 'test_interface_L3' primarily tests layer 3 interface properties.
#
###############################################################################
require File.expand_path('../interfacelib.rb', __FILE__)

# Test hash top-level keys
tests = {
  agent:         agent,
  master:        master,
  intf_type:     'ethernet',
  resource_name: 'cisco_interface',
}

# Find a usable interface for this test
intf = find_interface(tests)

# Test hash test cases
tests[:default] = {
  desc:               '1.1 Default Properties',
  title_pattern:      intf,
  code:               [0],
  preclean_intf:      true,
  sys_def_switchport: false,
  manifest_props:     {
    description:          'default',
    duplex:               'default',
    ipv4_forwarding:      'default',
    ipv4_pim_sparse_mode: 'default',
    ipv4_proxy_arp:       'default',
    ipv4_redirects:       'default',
    mtu:                  'default',
    shutdown:             'default',
    vrf:                  'default',
  },
  resource:           {
    duplex:               'auto',
    ipv4_forwarding:      'false',
    ipv4_pim_sparse_mode: 'false',
    ipv4_proxy_arp:       'false',
    ipv4_redirects:       operating_system == 'nexus' ? 'true' : 'false',
    mtu:                  operating_system == 'nexus' ? '1500' : '1514',
    shutdown:             'false',
  },
}

tests[:non_default] = {
  desc:               '2.1 Non Default Properties',
  title_pattern:      intf,
  sys_def_switchport: false,
  manifest_props:     {
    description:                   'Configured with Puppet',
    shutdown:                      true,
    ipv4_address:                  '1.1.1.1',
    ipv4_netmask_length:           31,
    ipv4_address_secondary:        '2.2.2.2',
    ipv4_netmask_length_secondary: 31,
    ipv4_pim_sparse_mode:          true,
    ipv4_proxy_arp:                true,
    ipv4_redirects:                operating_system == 'nexus' ? false : true,
    switchport_mode:               'disabled',
    vrf:                           'test1',
  },
}

tests[:acl] = {
  desc:               '2.2 ACL Properties',
  title_pattern:      intf,
  operating_system:   'nexus',
  sys_def_switchport: false,
  manifest_props:     {
    switchport_mode: 'disabled',
    ipv4_acl_in:     'v4_in',
    ipv4_acl_out:    'v4_out',
    ipv6_acl_in:     'v6_in',
    ipv6_acl_out:    'v6_out',
  },
  # ACLs must exist on some platforms
  acl:                {
    'v4_in'  => 'ipv4',
    'v4_out' => 'ipv4',
    'v6_in'  => 'ipv6',
    'v6_out' => 'ipv6',
  },
}

# Note: This test should follow the default test as it requires an
# L3 parent interface and this makes it easy to set up.
tests[:dot1q] = {
  desc:           '2.3 dot1q Sub-interface',
  title_pattern:  "#{intf}.1",
  manifest_props: { encapsulation_dot1q: 30 },
}

# This test should be run last since it will break ip addressing properties.
# Note that any tests that follow need to preclean.
tests[:ip_forwarding] = {
  desc:               '2.4 IP forwarding',
  title_pattern:      intf,
  preclean_intf:      true,
  sys_def_switchport: false,
  manifest_props:     { ipv4_forwarding: true },
}

def unsupported_properties(_tests, id)
  unprops = []

  if operating_system == 'ios_xr'
    unprops <<
      :duplex <<
      :ipv4_forwarding <<
      :ipv4_pim_sparse_mode <<
      :switchport_mode
  end

  # TBD: shutdown has unpredictable behavior. Needs investigation.
  unprops << :shutdown if id == :default

  unprops
end

#################################################################
# TEST CASE EXECUTION
#################################################################
test_name "TestCase :: #{tests[:resource_name]}" do
  # -------------------------------------------------------------------
  logger.info("\n#{'-' * 60}\nSection 1. Default Property Testing")
  test_harness_run(tests, :default)
  test_harness_run(tests, :dot1q)

  # -------------------------------------------------------------------
  logger.info("\n#{'-' * 60}\nSection 2. Non Default Property Testing")
  test_harness_run(tests, :non_default)
  test_harness_run(tests, :acl)
  test_harness_run(tests, :ip_forwarding)

  # -------------------------------------------------------------------
  interface_cleanup(agent, intf)
  skipped_tests_summary(tests)
end

logger.info("TestCase :: #{tests[:resource_name]} :: End")
