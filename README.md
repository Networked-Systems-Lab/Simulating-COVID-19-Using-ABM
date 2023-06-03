# Studying the Impact of Transportation During Lockdown on the Spread of COVID-19 Using Agent-based Modeling
Shikha Bhat, Ruturaj Godse, Shruti Mestry, and Vinayak Naik

## Abstract
The COVID-19 pandemic has posed challenges for governments concerning lockdown policies and transportation plans. The exponential rise in infections has highlighted the importance of managing restrictions on travel. Previous research around this topic has not been able to scale and address this issue for India, given its diversity in transportation networks and population across different states. In this study, we analyze the patterns of the spread of infection, recovery, and death specifically for the state of Goa, India, for twenty-eight days. Using agent-based simulations, we explore how individuals interact and spread the disease when traveling by trains, flights, and buses in two significant settings - unrestricted and restricted local movements. Our findings indicate that trains cause the highest spread of infection within the state, followed by flights and then buses. Contrary to what may be assumed, we find that the effect of combinations of all modes of transport is not additive. With multiple modes of transport activities, the cases rise exponentially faster. We present equivalence points for the number of vehicles running per day in unrestricted and restricted movement settings, e.g., one train a day in unrestricted movement spreads the disease as eight trains a day in restricted movement.


## Running the Code
There are two ways to run the simulation - with the GUI and without the GUI.
### Run with GUI
#### Single Run
1. Open the source file (abm-model.nlogo) with Netlogo application (version 6.2.0).
2. Click on the Interface tab.
3. You can set the required parameter values here. The paramater gets assigned a default value if not specified by the user.
4. Click on the Setup button to set the environment (world). You can see the environment in the view section.
5. Click on the Go button to start the simulation. 
6. The simulation will run for 28 days and then stop automatically.

#### Multiple Runs
1. Open the source file (abm-model.nlogo) with Netlogo application (version 6.2.0).
2. Click on Tools -> BehaviourSpace.
3. Click on New to setup a new experiment.
4. Give a name to the experiment. Add the list of values for each parameter with which you want to simulate the experiment. Netlogo runs multiple simulations with all the combinations of the parameter values. Click on Ok to create the experiment.
5. You can also select a previously created experiment from the list of experiments.
6. Click on the experiment to select it and click Run.
7. Select the options that you want in the pop up and specify the number of runs to be conducted simulataneously in parallel.
8. Click on Ok to start the simulations.
9. Multiple simulations will start running in parallel. Each one will run for 28 days and then stop automatically.


### Run without GUI
1. Set up the experiment in BehaviourSpace as mentioned in the previous section.
2. Open the terminal.
3. Move to the directory where the Netlogo application is stored.
4. Run the following command-
```sh
bash netlogo-headless.sh --model <netlogo_file_path> --experiment <experiment_name>
```
5. The experiment will start running - multiple runs in parallel as specified in the experiment.


## Publication

Please find our research paper published in Proceedings of the 15th International Conference on Agents and Artificial Intelligence - Volume 1: ICAART · Feb 24, 2023 [here](https://www.scitepress.org/PublicationsDetail.aspx?ID=Ermi1uq5VHY=&t=1) and the PDF version [here](https://github.com/Networked-Systems-Lab/Simulating-COVID-19-Using-ABM/blob/main/_Short_ICAART__COVID_19_Simulations.pdf). We request the reader to cite our paper if they find our work useful.

```
@conference{icaart23,
author={Shikha Bhat. and Ruturaj Godse. and Shruti Mestry. and Vinayak Naik.},
title={Studying the Impact of Transportation During Lockdown on the Spread of COVID-19 Using Agent-Based Modeling},
booktitle={Proceedings of the 15th International Conference on Agents and Artificial Intelligence - Volume 1: ICAART},
year={2023},
pages={80-92},
publisher={SciTePress},
organization={INSTICC},
doi={10.5220/0011733400003393},
isbn={978-989-758-623-1},
issn={2184-433X},
}
```
