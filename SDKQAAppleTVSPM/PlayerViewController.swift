//
//  PlayerViewController.swift
//  SDKQAAppleTVSPM
//
//  Pantalla de un caso: el player a la izquierda y el registro de eventos a la derecha.
//
//  El layout es lado a lado y no apilado como en iOS porque la pantalla es 16:9 apaisada:
//  un player arriba y una lista abajo desperdicia el ancho y deja el log en una franja de
//  pocas líneas. Así el video mantiene su relación de aspecto y el log muestra ~25 eventos.
//

import UIKit
import MediastreamPlatformSDKAppleTV

final class PlayerViewController: UIViewController {

    private let testCase: TestCase
    private var sdk: MediastreamPlatformSDK?

    private let playerContainer = UIView()
    private let logTable = UITableView(frame: .zero, style: .plain)
    private let headerLabel = UILabel()

    init(testCase: TestCase) {
        self.testCase = testCase
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no soportado") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .qaBackground

        buildLayout()
        EventLog.shared.clear()
        EventLog.shared.onChange = { [weak self] in self?.reloadLog() }

        loadPlayer()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent { teardown() }
    }

    /// El foco arranca en el player, no en la tabla de eventos: lo que se prueba es la
    /// reproducción, y en tvOS quien tiene el foco recibe el control remoto. La tabla se
    /// alcanza moviendo a la derecha.
    /// El foco es siempre del player. Antes caia en la tabla de eventos y no habia forma de
    /// recuperarlo.
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if let player = sdk { return [player.view] }
        return []
    }

    // MARK: - Layout

    /// En tvOS, `AVPlayerViewController` —que es lo que el SDK usa por dentro— está
    /// pensado para presentarse a pantalla completa. Con el player en un contenedor chico
    /// puede no reproducir, así que este modo lo pone a pantalla completa y saca el panel
    /// de eventos, para poder separar "el SDK no reproduce" de "el layout no le sirve".
    private var isFullscreen: Bool {
        testCase.fullscreen || ProcessInfo.processInfo.arguments.contains("--fullscreen")
    }

    private func buildLayout() {
        if isFullscreen {
            playerContainer.backgroundColor = .black
            playerContainer.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(playerContainer)
            NSLayoutConstraint.activate([
                playerContainer.topAnchor.constraint(equalTo: view.topAnchor),
                playerContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                playerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                playerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
            view.layoutIfNeeded()
            return
        }

        playerContainer.backgroundColor = .black
        playerContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerContainer)

        // La versión sale de getVersion(), que la lee del bundle del framework. Sirve para
        // que un reporte de QA diga contra qué build se probó, sin depender de memoria.
        headerLabel.text = "\(testCase.title)  ·  SDK \(MediastreamPlatformSDK().getVersion())\n\(testCase.detail)"
        headerLabel.numberOfLines = 0
        headerLabel.font = .qaMono(20)
        headerLabel.textColor = .qaSecondaryLabel
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerLabel)

        logTable.dataSource = self
        // Sin foco a proposito. En tvOS quien tiene el foco recibe el control remoto, y una
        // tabla enfocable al lado del player se lo roba: a partir de ahi no se puede dar
        // play, pausar ni navegar, y con customUI la UI del SDK no vuelve a aparecer. El log
        // no necesita foco porque se auto-desplaza al ultimo evento.
        logTable.isUserInteractionEnabled = false
        logTable.backgroundColor = .qaPanel
        logTable.rowHeight = UITableView.automaticDimension
        logTable.estimatedRowHeight = 34
        logTable.register(EventCell.self, forCellReuseIdentifier: EventCell.reuseID)
        logTable.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logTable)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: safe.topAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            headerLabel.trailingAnchor.constraint(equalTo: safe.trailingAnchor),

            playerContainer.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 24),
            playerContainer.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            playerContainer.widthAnchor.constraint(equalTo: safe.widthAnchor, multiplier: 0.62),
            playerContainer.heightAnchor.constraint(equalTo: playerContainer.widthAnchor,
                                                    multiplier: 9.0 / 16.0),

            logTable.topAnchor.constraint(equalTo: playerContainer.topAnchor),
            logTable.leadingAnchor.constraint(equalTo: playerContainer.trailingAnchor, constant: 24),
            logTable.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            logTable.bottomAnchor.constraint(equalTo: safe.bottomAnchor),
        ])
    }

    // MARK: - Player

    private func loadPlayer() {
        let config = MediastreamPlayerConfig()
        testCase.configure(config)

        let player = MediastreamPlatformSDK()
        sdk = player

        addChild(player)
        player.view.frame = playerContainer.bounds
        player.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerContainer.addSubview(player.view)
        player.didMove(toParent: self)

        // Antes del setup, para no perder los eventos de la carga inicial.
        SDKEventListeners.attachAll(to: player.events)

        player.setup(config)
        player.play()

        setNeedsFocusUpdate()
        updateFocusIfNeeded()

    }

    private func teardown() {
        guard let player = sdk else { return }
        player.releasePlayer()
        player.willMove(toParent: nil)
        player.view.removeFromSuperview()
        player.removeFromParent()
        sdk = nil
        EventLog.shared.onChange = nil
    }

    // MARK: - Log

    private func reloadLog() {
        logTable.reloadData()
        let last = EventLog.shared.entries.count - 1
        guard last >= 0 else { return }
        logTable.scrollToRow(at: IndexPath(row: last, section: 0), at: .bottom, animated: false)
    }
}

/// Celda del log.
///
/// Existe en vez de usar el `textLabel` que trae `UITableViewCell` porque ese label no
/// participa de auto layout en tvOS: con `rowHeight = .automaticDimension` la fila queda de
/// altura cero y el evento se registra sin verse. Este label sí está anclado al
/// contentView, así que la fila crece con el texto.
private final class EventCell: UITableViewCell {

    static let reuseID = "event"
    let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        label.font = .qaMono(18)
        label.textColor = .white
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no soportado") }
}

// MARK: - UITableViewDataSource

extension PlayerViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        EventLog.shared.entries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: EventCell.reuseID,
                                                 for: indexPath) as! EventCell
        cell.label.text = EventLog.shared.line(at: indexPath.row)
        return cell
    }
}
