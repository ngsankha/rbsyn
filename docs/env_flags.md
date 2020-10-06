# Environment Variable Flags

The system supports different features via environment variables:

* `CONSOLE_LOG`: Logs the syntax highlighted synthesized program to the console.
* `DISABLE_TYPES`: Disables typed directed synthesis of terms.
* `DISABLE_EFFECTS`: Disables effect guided synthesis.
* `LOG`: If set to `DEBUG` prints status messages of synthesis in the engine
* `EFFECT_PREC`: any non-negative integer. 0 means most precise, 1 means reduce precision of all effects by 1 level, 2 means reduce precision by 2 levels.
