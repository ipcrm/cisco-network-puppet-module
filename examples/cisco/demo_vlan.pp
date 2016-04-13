# Manifest to demo cisco_vlan provider
#
# Copyright (c) 2014-2016 Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class ciscopuppet::cisco::demo_vlan {
  $mapped_vni = platform_get() ? {
    /(n3k|n9k)/ => 22000,
    default => undef
  }
  cisco_vlan { '220':
    ensure     => present,
    mapped_vni => $mapped_vni,
    vlan_name  => 'newtest',
    shutdown   => true,
    state      => 'active',
  }
  # For private vlan
  cisco_vlan { '120':
    ensure     => present,
    private_vlan_type => 'primary',
    private_vlan_association => ['200', '300-304'],
  }

}
