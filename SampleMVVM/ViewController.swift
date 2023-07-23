//
//  ViewController.swift
//  SampleMVVM
//
//  Created by 부재식 on 2023/07/22.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class ViewController: UIViewController {
    private var viewModel = ViewModel()
    private var bag = DisposeBag()
    
    lazy var tableView : UITableView = {
        let tv = UITableView(frame: self.view.frame, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(UserTableViewCell.self, forCellReuseIdentifier: "UserTableViewCell")
        return tv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.addSubview(tableView)
        let add = UIBarButtonItem(title: "Add", style: .done, target: self, action: #selector(onTapAdd))
        self.navigationItem.rightBarButtonItem = add
        viewModel.fetchUsers()
        bindTableView()
    }
    
    @objc func onTapAdd() {
        let user = User(userId: 48954, id: 4534, title: "CodeLib", body: "RxSwift Crud")
        self.viewModel.addUser(user: user)
        
    }
    
    func bindTableView() {
        tableView.rx.setDelegate(self).disposed(by: bag)
//        viewModel.users.bind(to: tableView.rx.items(cellIdentifier: "UserTableViewCell", cellType: UserTableViewCell.self)) { (row, item, cell) in
//            cell.textLabel?.text = item.title
//            cell.detailTextLabel?.text = "\(item.id)"
//        }.disposed(by: bag)
//
//        tableView.rx.itemSelected.subscribe(onNext: { indexPath in
////            print(indexPath.row)
//            let alert = UIAlertController(title: "Note", message: "Edit Note", preferredStyle: .alert)
//            alert.addTextField { textfield in
//
//            }
//            alert.addAction(UIAlertAction(title: "Edit", style: .default, handler: { action in
//                let textField = alert.textFields![0] as UITextField
//                self.viewModel.editUser(title: textField.text ?? "", index: indexPath.row)
//            }))
//
//            DispatchQueue.main.async {
//                self.present(alert, animated: true, completion: nil)
//            }
//        }).disposed(by: bag)
//
//        tableView.rx.itemDeleted.subscribe(onNext: { [weak self] indexPath in
//            guard let self = self else {return}
//            self.viewModel.deleteUser(index: indexPath.row)
//        }).disposed(by: bag)
        
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, User>>{
            _, tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserTableViewCell", for: indexPath) as! UserTableViewCell
            cell.textLabel?.text = item.title
            cell.detailTextLabel?.text = "\(item.id)"
            return cell
        } titleForHeaderInSection: { dataSource, sectionIndex in
            return dataSource[sectionIndex].model
        }
        
        self.viewModel.users.bind(to: self.tableView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
        
        tableView.rx.itemDeleted.subscribe(onNext: { [weak self] indexPath in
            guard let self = self else {return}
            self.viewModel.deleteUser(indexPath: indexPath)
        }).disposed(by: bag)
        
        tableView.rx.itemSelected.subscribe(onNext: { indexPath in
            let alert = UIAlertController(title: "Note", message: "Edit Note", preferredStyle: .alert)
            alert.addTextField { textfield in
                
            }
            
            alert.addAction(UIAlertAction(title: "Edit", style: .default, handler: { action in
                let textField = alert.textFields![0] as UITextField
                self.viewModel.editUser(title: textField.text ?? "", indexPath: indexPath)
            }))
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        }).disposed(by: bag)
    }
}

extension ViewController : UITableViewDelegate {
    
}

class ViewModel {
    var users = BehaviorSubject(value: [SectionModel(model: "", items: [User]())])
    
    func fetchUsers() {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")
        let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            guard let data = data else {return}
            do {
                let responseData = try JSONDecoder().decode([User].self, from: data)
//                self.users.on(.next(responseData))
                let sectionUser = SectionModel(model: "First", items: [User(userId: 0, id: 1, title: "CodeLib", body: "Youtube demo")])
                let secondSection = SectionModel(model: "Second", items: responseData)
                self.users.on(.next([sectionUser, secondSection]))
            } catch  {
                print(error.localizedDescription)
            }
        }
        task.resume()
    }
    
    func addUser(user: User){
        guard var sections = try? users.value() else {return}
        var currentSection = sections[0]
        currentSection.items.append(User(userId: 2, id: 32, title: "New Dataaa", body: "example"))
        sections[0] = currentSection
        self.users.onNext(sections)

    }
    
    func deleteUser(indexPath: IndexPath) {
        guard var sections = try? users.value() else {return}
        var currentSection = sections[indexPath.section]
        currentSection.items.remove(at: indexPath.row)
        sections[indexPath.section] = currentSection
        self.users.onNext(sections)
        
    }
    
    func editUser(title: String, indexPath: IndexPath) {
        guard var sections = try? users.value() else {return}
        var currentSection = sections[indexPath.section]
        currentSection.items[indexPath.row].title = title
        sections[indexPath.section] = currentSection
        self.users.onNext(sections)
    }
}

struct User: Codable {
    let userId, id: Int
    var title, body: String
    
    enum Codingkeys: String, CodingKey {
        case userID = "userId"
        case id, title, body
    }
}

