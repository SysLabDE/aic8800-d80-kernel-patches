# Targeted Driver Patches

Apply these files in order to the Linux kernel tree or the standalone driver source before building.

- **`rwnx_main.c.patch`** — Core wireless LAN controller patch.
  - Corrects `cfg80211_ops` signature updates.
  - Fixes `radio_idx` and `link_id` argument changes on Kernel >= 7.x.
  - Transitions interrupt context from `in_irq` to `in_serving_softirq`.

- **`rmi_main.c.patch`** — USB/PCI core bridge (if required).
