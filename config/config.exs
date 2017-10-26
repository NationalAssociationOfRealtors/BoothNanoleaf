# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :booth_nanoleaf, interface: :wlan0

config :logger, level: :info

config :nerves, :firmware,
  rootfs_overlay: "config/rootfs_overlay"

config :nerves_ntp, :ntpd, "/usr/sbin/ntpd"
config :nerves_ntp, :servers, [
  "0.pool.ntp.org",
  "1.pool.ntp.org",
  "2.pool.ntp.org",
  "3.pool.ntp.org"
]

config :nerves_network, :default,
  wlan0: [
    ssid: System.get_env("SSID"),
    psk: System.get_env("KEY"),
    key_mgmt: :"WPA-PSK"
  ],
  eth0: [
    ipv4_address_method: :dhcp
  ]

config :twittex,
  token: System.get_env("TWITTER_TOKEN"),
  token_secret: System.get_env("TWITTER_SECRET"),
  consumer_key: System.get_env("TWITTER_CONSUMER_TOKEN"),
  consumer_secret: System.get_env("TWITTER_CONSUMER_SECRET")

# Customize the firmware. Uncomment all or parts of the following
# to add files to the root filesystem or modify the firmware
# archive.

# config :nerves, :firmware,
#   rootfs_overlay: "rootfs_overlay",
#   fwup_conf: "config/fwup.conf"

# Use bootloader to start the main application. See the bootloader
# docs for separating out critical OTP applications such as those
# involved with firmware updates.
config :bootloader,
  init: [:nerves_runtime, :nerves_network, :nerves_firmware_http, :nerves_ntp, :ieq_gateway, :nanoleaf, :twittex, :gen_stage],
  app: :booth_nanoleaf

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations

# import_config "#{Mix.Project.config[:target]}.exs"
