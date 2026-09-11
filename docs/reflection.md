# Unit 1 Reflection — Linxuan Ma

My original STATS 500 analysis consisted of a single Quarto document
and a separate PDF report. Data cleaning, exploratory plots, model
comparison, and evaluation were arranged sequentially in the document.
Reproduction depended on a locally stored 4.34 GB CSV, available R
packages, and the working directory. Package versions were not locked,
and there were no automated tests or a documented reproduction command.

The most time-consuming component was reconstructing the original
cleaning process and checking it against the saved analysis data.
Preserving the order of sampling and percentile filtering mattered.
The rebuilt data contained 187,524 observations, with matching trip
IDs and row order; the six analysis variables also passed a numerical
comparison. Another challenge was discovering that RStudio and my
terminal used different R installations despite both reporting
version 4.5.1. Selecting the same installation resolved the package
library mismatch.

The most useful improvements were the small, shareable checkpoint,
the renv lockfile, and a single entry point with separate checkpoint
and raw-data modes. Focused Git commits preserved the original state
and documented the transformation. Two test categories checked data
validity and regenerated outputs in a temporary directory without
existing results. A fresh local Git clone also generated all seven
outputs and passed 40 assertions while leaving its working tree clean.
This was a same-machine check, not cross-platform validation.

In future projects, I would establish the directory structure and
environment at the beginning, document the exact data export, write
reusable functions earlier, and keep a contemporaneous work log.
I would also separate model selection and preprocessing decisions
from final test-set evaluation. This project preserved the original
analysis rather than redesigning its statistical methodology.

ChatGPT provided extensive step-by-step guidance, drafted much of the
refactored code and documentation, and helped diagnose errors. I
executed the commands locally, reviewed outputs, and supplied results
and error messages for troubleshooting. Verification included
checkpoint comparisons, agreement of reported R-squared values,
automated tests, and execution from a fresh clone. These checks do
not prove that all AI-generated code or statistical interpretations
are correct; some original report AIC values still differ slightly
from the computed results, and the discrepancy remains unresolved.

Total effort was approximately six hours. Retrospective estimates
are: project selection, structure and Git, 45 minutes; environment
setup and troubleshooting, 60 minutes; analysis and workflow
refactoring, 75 minutes; raw-data cleaning and comparisons, 90 minutes;
testing and clone verification, 60 minutes; and documentation,
30 minutes. These are approximate allocations, not recorded timings.