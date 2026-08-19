//
//  ViewController.swift
//  SDKQAAppleTVSPM
//
//  Lista de casos de prueba. Se arma sola desde TestCase.all, así que agregar un caso no
//  requiere tocar esta pantalla.
//

import UIKit
import MediastreamPlatformSDKAppleTV

final class ViewController: UIViewController {

    private let categories = TestCase.Category.allCases

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.dataSource = self
        table.delegate = self
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "SDK QA Apple TV — SPM"
        view.backgroundColor = .qaBackground
        view.addSubview(tableView)

        // safeArea y no los bordes: en tvOS incluye el overscan, y una tabla a sangre queda
        // con las filas cortadas en un televisor real.
        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: safe.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: safe.bottomAnchor),
        ])
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { categories.count }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        categories[section].rawValue
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        // La versión del SDK viene del bundle del framework, no de una constante: es la que
        // se publicó. En un build local diría 0.0.0-local.
        section == categories.count - 1
            ? "SDK \(MediastreamPlatformSDK().getVersion()) · distribuido por Swift Package Manager"
            : nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        TestCase.cases(in: categories[section]).count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "case")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "case")
        let item = TestCase.cases(in: categories[indexPath.section])[indexPath.row]
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.detail
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = TestCase.cases(in: categories[indexPath.section])[indexPath.row]
        navigationController?.pushViewController(PlayerViewController(testCase: item), animated: true)
    }
}
