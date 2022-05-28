# ABM

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
