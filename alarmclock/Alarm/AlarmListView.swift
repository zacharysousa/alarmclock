import SwiftUI
import SwiftData

struct AlarmListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Alarm.hour, order: .forward) private var alarms: [Alarm]
    @State private var viewModel = AlarmViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if alarms.isEmpty {
                    emptyState
                } else {
                    alarmList
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            viewModel.addAlarm(context: context)
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2.bold())
                                .foregroundStyle(.black)
                                .frame(width: 56, height: 56)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationTitle("Alarm")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.black, for: .navigationBar)
            .sheet(isPresented: $viewModel.isShowingEditor) {
                if let alarm = viewModel.editingAlarm {
                    AlarmEditorView(alarm: alarm, viewModel: viewModel)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "alarm")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            Text("No Alarms")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Tap + to add your first alarm")
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
    }

    private var alarmList: some View {
        List {
            ForEach(alarms) { alarm in
                AlarmRowView(alarm: alarm) {
                    viewModel.edit(alarm)
                } onToggle: {
                    viewModel.toggle(alarm, context: context)
                }
                .listRowBackground(Color(white: 0.1))
                .listRowSeparatorTint(.gray.opacity(0.3))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        viewModel.delete(alarm, context: context)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

struct AlarmRowView: View {
    @Bindable var alarm: Alarm
    let onTap: () -> Void
    let onToggle: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(alarm.timeString)
                        .font(.system(size: 42, weight: .thin, design: .rounded))
                        .foregroundStyle(alarm.isEnabled ? .white : .gray)

                    Text(alarm.repeatSummary)
                        .font(.caption)
                        .foregroundStyle(alarm.isEnabled ? .gray : .gray.opacity(0.5))

                    if !alarm.label.isEmpty {
                        Text(alarm.label)
                            .font(.caption)
                            .foregroundStyle(alarm.isEnabled ? .white.opacity(0.7) : .gray.opacity(0.5))
                    }

                    if !alarm.missions.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(alarm.missions.prefix(3)) { mission in
                                Image(systemName: mission.type.systemIcon)
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                            if alarm.missions.count > 3 {
                                Text("+\(alarm.missions.count - 3)")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { alarm.isEnabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
                .tint(.orange)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
