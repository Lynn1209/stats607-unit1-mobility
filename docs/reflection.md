# Unit 1 Reflection — Linxuan Ma

I used my previous STATS 500 project for this assignment. It had one Quarto file and a PDF report. Running it depended on a large CSV saved on my computer and the packages I had installed. I had not recorded package versions or added automated tests, so it would have been difficult for someone else to reproduce.

The hardest part was rebuilding the cleaned data and checking it against my saved data. The order of sampling and filtering mattered. The rebuilt data had the same 187,524 rows, trip IDs, and row order, and the six analysis variables matched in the comparison. Another problem was that RStudio and my terminal used different R installations. Using the same installation fixed the package-library issue.

The most useful changes were separating the analysis into scripts, recording package versions with renv, and adding one command to reproduce the results. I also included the cleaned data so the analysis can run without downloading the large CSV. The tests checked the data and regenerated outputs. A fresh local clone produced all seven outputs and passed the tests on my Mac. I have not tested it on another computer.

Next time, I would organize the files and record dependencies at the beginning. I would also keep notes about errors and time spent, rather than trying to remember them later.

I used ChatGPT for step guidance, help drafting code and documentation, and troubleshooting. I ran the commands locally and checked the results through data comparisons, automated tests, and a fresh local clone. Some AIC values still differed slightly from the original report, so I cannot claim that every reported result matched exactly.

My current estimate is about eight to nine hours overall. I did not keep a time log, so the total is approximate. Rebuilding and checking the raw-data cleaning took the most time. The other main tasks were setting up Git and the project folders, configuring the R environment, refactoring the analysis, testing, and writing the documentation.
