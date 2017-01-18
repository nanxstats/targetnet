TargetNet is an open-source web application for predicting the binding probability of 623 potential drug targets for given molecule(s).

In drug discovery, one of the big challenges is to identify the potential drug targets for drug-like compounds. However, this could be a difficult task for medicinal chemists. To address such difficulty, we used [BindingDB](https://www.bindingdb.org/) to construct the training sets. BindingDB is a public database of experimentally measured binding affinities, mainly focusing on the interactions of proteins considered to be candidate target with ligands that are small, drug-like molecules.

Activity data were filtered with the following process:

1. Keep only activity end-point points that had half-maximum inhibitory concentration (IC50), half-maximum effective concentration (EC50) or Ki values;
2. A compound is considered active when the mean activity value is below 10 uM. All compounds with activity higher than 10 uM are considered inactive;
3. To ensure that enough number of molecules could be used in model building, only the targets with larger than 200 biological activity data are included.

After this filtering, 109,061 compounds associated with 623 target proteins remained with 115,257 activity end-points, are used for modeling. A set of Random Forest classification models is built using the training set. FP2 fingerprints were computed from the drug-like molecules as features. For each predictive model, a repeated (10 times) 5-fold cross-validation was applied to evaluate the prediction performance. Model performance evaluation metrics include AUC, Accuracy, BEDROC (Boltzmann-Enhanced Discrimination of ROC), MCC, and F-score. Eventually, a model was built with the complete dataset and scored against itself --- the training set and whole set should provide similar validation statistics.

<hr>

Copyright © 2014 - 2016 TargetNet. Developed and maintained by [Nan Xiao](https://nanx.me).
