// source/BreathworkApp.mc
/*
This is the main application file. It contains the logic for the app's lifecycle,
UI updates, sensor data handling, and the breathing exercise state machine.
*/
using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Timer;
using Toybox.Sensor;
using Toybox.Activity;
using Toybox.FitContributor;

// Main Application Class
class BreathworkApp extends App.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // Return the initial view of the application here
    function getInitialView() {
        return [ new BreathworkView(), new BreathworkDelegate() ];
    }
}

// Main View Class
class BreathworkView extends Ui.View {
    private var _instructionLabel;
    private var _timerLabel;
    private var _hrValueLabel;
    private var _stressValueLabel;
    private var _spo2ValueLabel;

    var exerciseState = :stopped; // :stopped, :inhale, :hold1, :exhale, :hold2
    var timerValue = 4;

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));

        _instructionLabel = findDrawableById("instructionLabel");
        _timerLabel = findDrawableById("timerLabel");
        _hrValueLabel = findDrawableById("hrValueLabel");
        _stressValueLabel = findDrawableById("stressValueLabel");
        _spo2ValueLabel = findDrawableById("spo2ValueLabel");
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
        // Update labels based on exercise state
        switch(exerciseState) {
            case :stopped:
                _instructionLabel.setText("Press Start");
                _timerLabel.setText("");
                break;
            case :inhale:
                _instructionLabel.setText("Inhale");
                _timerLabel.setText(timerValue.toString());
                break;
            case :hold1:
                _instructionLabel.setText("Hold");
                _timerLabel.setText(timerValue.toString());
                break;
            case :exhale:
                _instructionLabel.setText("Exhale");
                _timerLabel.setText(timerValue.toString());
                break;
            case :hold2:
                _instructionLabel.setText("Hold");
                _timerLabel.setText(timerValue.toString());
                break;
        }

        View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    function updateSensorData(sensorInfo) {
        if (sensorInfo has :heartRate && sensorInfo.heartRate != null) {
            _hrValueLabel.setText(sensorInfo.heartRate.toString());
        } else {
            _hrValueLabel.setText("--");
        }

        if (sensorInfo has :stressScore && sensorInfo.stressScore != null) {
            _stressValueLabel.setText(sensorInfo.stressScore.toString());
        } else {
            _stressValueLabel.setText("--");
        }

        if (sensorInfo has :oxygenSaturation && sensorInfo.oxygenSaturation != null) {
            _spo2ValueLabel.setText(sensorInfo.oxygenSaturation.format("%.1f") + "%");
        } else {
            _spo2ValueLabel.setText("--");
        }
        Ui.requestUpdate();
    }
}

// Behavior Delegate Class
class BreathworkDelegate extends Ui.BehaviorDelegate {

    private var _view;
    private var _timer;
    private var _session;

    function initialize() {
        BehaviorDelegate.initialize();
        _view = new BreathworkView();
        _timer = new Timer.Timer();
        _session = null;
    }

    function onMenu() {
        Ui.pushView(new Rez.Menus.MainMenu(), new MainMenuDelegate(), Ui.SLIDE_UP);
        return true;
    }

    function onSelect() {
        if (_view.exerciseState == :stopped) {
            startExercise();
        } else {
            stopExercise();
        }
        return true;
    }

    function startExercise() {
        _view.exerciseState = :inhale;
        _view.timerValue = 4;
        _timer.start(method(:timerCallback), 1000, true);
        
        // Start activity recording
        _session = Activity.createSession({
            :name => "Breathwork",
            :sport => Activity.SPORT_GENERIC,
            :subSport => Activity.SUB_SPORT_GENERIC
        });
        _session.start();

        // Enable sensors
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE, Sensor.SENSOR_PULSE_OXIMETRY]);
        Sensor.enableSensorEvents(method(:onSensorData));

        Ui.requestUpdate();
    }

    function stopExercise() {
        _view.exerciseState = :stopped;
        _timer.stop();

        // Stop activity recording
        if (_session != null) {
            _session.stop();
            _session.save();
            _session = null;
        }

        // Disable sensors
        Sensor.disableSensorEvents();

        Ui.requestUpdate();
    }

    function timerCallback() {
        _view.timerValue--;
        if (_view.timerValue == 0) {
            switch(_view.exerciseState) {
                case :inhale:
                    _view.exerciseState = :hold1;
                    _view.timerValue = 4;
                    break;
                case :hold1:
                    _view.exerciseState = :exhale;
                    _view.timerValue = 4;
                    break;
                case :exhale:
                    _view.exerciseState = :hold2;
                    _view.timerValue = 4;
                    break;
                case :hold2:
                    _view.exerciseState = :inhale;
                    _view.timerValue = 4;
                    break;
            }
        }
        Ui.requestUpdate();
    }

    function onSensorData(sensorInfo) {
        _view.updateSensorData(sensorInfo);
    }
}
