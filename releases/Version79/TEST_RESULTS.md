# V79 test results

**Offline checks pass; actual Studio testing remains required.**

| Actual production-code suite | Assertions |
| --- | ---: |
| conveyor | 212 |
| power | 933 |
| session | 171 |
| codec | 472 |
| cashshop | 287 |
| hud | 648 |
| server | 24 |
| index-preview | 7601 |
| profile | 147 |

The new tests first reproduced the V78 unowned-item disposal failure and automatic timed carry loss. They now verify repeated conveyor replenishment, exact visual cleanup, hologram/real-item separation, valid power drops, no paid-loss refund, later delivery, owner-only taken/recovered/stolen alerts, and safety guards. Full save/crash/receipt and existing ten-power tests still pass.

All 312 original place objects, all 76 collectible designs/stats and all unmodified source files match V78. The builder preserves backup sources and every non-source property. The packager checks current test/source hashes and ZIP integrity.

No live Studio multiplayer, touch/controller device, DataStore, receipt, physics/FPS or audio permission test was performed in this cloud. Use the V78 launch checklist plus the focused V79 Play checks in README.md.

Game SHA-256: `ee90a6c724e0f02405bb829e94731fcd744339e8710aef143ce57fee702139e3`.
