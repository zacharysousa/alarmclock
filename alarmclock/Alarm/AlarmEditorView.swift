import SwiftUI
import SwiftData

struct AlarmEditorView: View {
    @Environment(\.modelContext) private var context
    @Bindable var alarm: Alarm
    var viewModel: AlarmViewModel

    @State private var selectedHour: Int
    @State private var selectedMinute: Int
    @State private var showMissionPicker = false

    init(alarm: Alarm, viewModel: AlarmViewModel) {
        self.alarm = alarm
        self.viewModel = viewModel
        _selectedHour = State(initialValue: alarm.hour)
        _selectedMinute = State(initialValue: alarm.minute)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        timePicker
                        Divider().background(Color.gray.opacity(0.3))
                        repeatSection
                        Divider().background(Color.gray.opacity(0.3))
                        labelSection
                        Divider().background(Color.gray.opacity(0.3))
                        volumeSection
                        Divider().background(Color.gray.opacity(0.3))
                        missionsSection
                        Divider().background(Color.gray.opacity(0.3))
                        snoozeSection
                    }
                }
            }
            .navigationTitle(alarm.label.isEmpty ? "New Alarm" : alarm.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelEdit(alarm: alarm, context: context)
                    }
                    .foregroundStyle(.orange)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        alarm.hour = selectedHour
                        alarm.minute = selectedMinute
                        viewModel.save(alarm, context: context)
                    }
                    .foregroundStyle(.orange)
                }
            }
            .sheet(isPresented: $showMissionPicker) {
                MissionPickerView(alarm: alarm)
            }
        }
    }

    private var timePicker: some View {
        HStack(spacing: 0) {
            Picker("Hour", selection: $selectedHour) {
                ForEach(0..<24, id: \.self) { h in
                    Text(String(format: "%02d", h))
                        .tag(h)
                        .foregroundStyle(.white)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)

            Text(":")
                .font(.title.bold())
                .foregroundStyle(.white)

            Picker("Minute", selection: $selectedMinute) {
                ForEach(0..<60, id: \.self) { m in
                    Text(String(format: "%02d", m))
                        .tag(m)
                        .foregroundStyle(.white)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
        }
        .padding()
    }

    private var repeatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("REPEAT")
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.horizontal)
                .padding(.top, 16)

            HStack(spacing: 8) {
                ForEach(Weekday.allCases) { day in
                    let isSelected = alarm.repeatDays.contains(day)
                    Button {
                        var days = alarm.repeatDays
                        if isSelected { days.remove(day) } else { days.insert(day) }
                        alarm.repeatDays = days
                    } label: {
                        Text(day.shortName)
                            .font(.caption.bold())
                            .foregroundStyle(isSelected ? .black : .gray)
                            .frame(width: 36, height: 36)
                            .background(isSelected ? Color.orange : Color(white: 0.15))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }

    private var labelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LABEL")
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.horizontal)
                .padding(.top, 16)

            TextField("Alarm label", text: $alarm.label)
                .foregroundStyle(.white)
                .tint(.orange)
                .padding(.horizontal)
                .padding(.bottom, 16)
        }
    }

    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SOUND & VOLUME")
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.horizontal)
                .padding(.top, 16)

            HStack {
                Image(systemName: "speaker.fill")
                    .foregroundStyle(.gray)
                Slider(value: $alarm.volume, in: 0...1)
                    .tint(.orange)
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal)

            Toggle(isOn: $alarm.gradualVolume) {
                Text("Gradually increase volume")
                    .foregroundStyle(.white)
            }
            .tint(.orange)
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }

    private var missionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MISSIONS")
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.horizontal)
                .padding(.top, 16)

            if alarm.missions.isEmpty {
                Text("No missions set — alarm can be dismissed freely")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.horizontal)
            } else {
                ForEach(alarm.missions) { mission in
                    HStack {
                        Image(systemName: mission.type.systemIcon)
                            .foregroundStyle(.orange)
                            .frame(width: 24)
                        Text(mission.type.displayName)
                            .foregroundStyle(.white)
                        Spacer()
                        Text("Difficulty \(mission.difficulty)")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    .padding(.horizontal)
                }
            }

            Button {
                showMissionPicker = true
            } label: {
                Label("Add Mission", systemImage: "plus")
                    .foregroundStyle(.orange)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }

    private var snoozeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ANTI-SNOOZE")
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.horizontal)
                .padding(.top, 16)

            Toggle(isOn: $alarm.snoozeEnabled) {
                Text("Allow snooze")
                    .foregroundStyle(.white)
            }
            .tint(.orange)
            .padding(.horizontal)

            if alarm.snoozeEnabled {
                HStack {
                    Text("Snooze duration")
                        .foregroundStyle(.white)
                    Spacer()
                    Picker("", selection: $alarm.snoozeDuration) {
                        ForEach([1, 3, 5, 10, 15, 20], id: \.self) { min in
                            Text("\(min) min").tag(min)
                        }
                    }
                    .tint(.orange)
                }
                .padding(.horizontal)
            }

            Toggle(isOn: $alarm.wakeUpCheckEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Wake Up Check")
                        .foregroundStyle(.white)
                    Text("Restarts mission if alarm is ignored for 2 min")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            .tint(.orange)
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }
}

struct MissionPickerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var alarm: Alarm

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                List {
                    ForEach(MissionType.allCases) { type in
                        Button {
                            let mission = MissionConfig(type: type)
                            mission.alarm = alarm
                            context.insert(mission)
                            alarm.missions.append(mission)
                            dismiss()
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: type.systemIcon)
                                    .foregroundStyle(.orange)
                                    .frame(width: 28)
                                Text(type.displayName)
                                    .foregroundStyle(.white)
                            }
                        }
                        .listRowBackground(Color(white: 0.1))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Choose Mission")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}
