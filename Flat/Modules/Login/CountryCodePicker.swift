//
//  CountryCountPicker.swift
//  Flat
//
//  Created by xuyunshi on 2023/2/28.
//  Copyright © 2023 agora.io. All rights reserved.
//

import libPhoneNumber_iOS
import UIKit

struct Country {
    var code: String
    var name: String
    var phoneCode: String
    
    static func countryFor(regionCode id: String) -> Self? {
        guard let name = Locale.current.localizedString(forRegionCode: id)
        else { return nil }
        let cid = NBPhoneNumberUtil.sharedInstance().getCountryCode(forRegion: id).stringValue
        return .init(code: id, name: name, phoneCode: cid)
    }
    
    static func currentCountry() -> Self {
        guard let code = Locale.current.regionCode else { return .fallBack() }
        guard let country = countryFor(regionCode: code) else { return .fallBack() }
        return country
    }
    
    static func fallBack() -> Self { .init(code: "zh-cn", name: "China", phoneCode: "86")}
}

class CountryCodePicker: UIViewController {
    lazy var countrys = NSLocale.isoCountryCodes
        .compactMap { Country.countryFor(regionCode: $0) }
        .sorted(by: { $0.name < $1.name })
    var searchedCountry: [Country] = []
    var pickingHandler: ((Country) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
        // Select to current region after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let currnetRegionCode = Locale.current.regionCode {
                if let index = self.countrys.firstIndex(where: { $0.code == currnetRegionCode }) {
                    self.tableView.selectRow(at: .init(row: index, section: 0), animated: false, scrollPosition: .top)
                }
            }
        }
    }
    
    func setupViews() {
        title = localizeStrings("CountryCodeSelection")
        let stackView = UIStackView(arrangedSubviews: [searchBar, tableView])
        stackView.axis = .vertical
        stackView.distribution = .fill
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        view.backgroundColor = .color(type: .background)
    }
    
    lazy var searchBar: UISearchBar = {
        let bar = UISearchBar(frame: .zero)
        bar.delegate = self
        bar.placeholder = "Searching"
        return bar
    }()
    
    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.backgroundColor = .color(type: .background)
        view.delegate = self
        view.dataSource = self
        view.register(CountryCell.self, forCellReuseIdentifier: "cell")
        view.rowHeight = 66
        return view
    }()
    
    var searching = false {
        didSet {
            tableView.reloadData()
        }
    }
}

extension CountryCodePicker: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchedCountry = countrys.filter {
            $0.name.prefix(searchText.count) == searchText || $0.phoneCode == searchText
        }
        searching = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searching = false
    }
}

extension CountryCodePicker: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        (searching ? searchedCountry : countrys).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! CountryCell
        let country = (searching ? searchedCountry : countrys)[indexPath.row]
        cell.countryCodeLabel.text = "+" + country.phoneCode
        cell.countryNameLabel.text = country.name
        cell.flagImageView.image = UIImage(named: country.code.lowercased())
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let country = (searching ? searchedCountry : countrys)[indexPath.row]
        pickingHandler?(country)
    }
}

class CountryCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let spacing = UIView()
        let stack = UIStackView(arrangedSubviews: [flagImageView, countryNameLabel, spacing, countryCodeLabel])
        stack.axis = .horizontal
        stack.spacing = 14
        stack.distribution = .fill
        contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14))
        }
        flagImageView.snp.makeConstraints { make in
            make.width.equalTo(44)
        }
    }
    
    lazy var flagImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    lazy var countryNameLabel: UILabel = {
        let label = UILabel()
        return label
    }()

    lazy var countryCodeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray
        return label
    }()
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
