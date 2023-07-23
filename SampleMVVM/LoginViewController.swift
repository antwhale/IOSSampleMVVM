//
//  LoginViewController.swift
//  SampleMVVM
//
//  Created by 부재식 on 2023/07/23.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit

class LoginViewController : UIViewController {
    //Create textfield
    lazy var textFieldEmail : UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter Email"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .emailAddress
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    lazy var textfieldPassword : UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter Password"
        textField.borderStyle = .roundedRect
        textField.isSecureTextEntry = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    //login button
    lazy var btnLogin : UIButton = {
       let btn = UIButton()
        btn.setTitle("Login", for: .normal)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.setTitleColor(UIColor.white.withAlphaComponent(0.3), for: .highlighted)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.backgroundColor = UIColor.systemRed
        btn.addTarget(self, action: #selector(onTapBtnLogin), for: .touchUpInside)
        return btn
    }()
    
    var bag = DisposeBag()
    private let viewModel = LoginViewModel()
    
    @objc func onTapBtnLogin() {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        createObservables()
    }
    
    private func setupUI() {
        self.view.backgroundColor = .white
        self.view.addSubview(textFieldEmail)
        self.view.addSubview(textfieldPassword)
        self.view.addSubview(btnLogin)
        
        NSLayoutConstraint.activate([
            textFieldEmail.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            textFieldEmail.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            textFieldEmail.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textfieldPassword.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            textfieldPassword.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            textfieldPassword.topAnchor.constraint(equalTo: textFieldEmail.bottomAnchor, constant: 20),
            btnLogin.topAnchor.constraint(equalTo: textfieldPassword.bottomAnchor, constant: 20),
            btnLogin.widthAnchor.constraint(equalTo: textFieldEmail.widthAnchor),
            btnLogin.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
        ])
    }
    
    private func createObservables() {
        textFieldEmail.rx.text.map({$0 ?? ""})
            .bind(to: viewModel.email)
            .disposed(by: bag)
        
        textfieldPassword.rx.text.map({$0 ?? ""})
            .bind(to: viewModel.password)
            .disposed(by: bag)
        
        viewModel.isValidInput.bind(to: btnLogin.rx.isEnabled)
            .disposed(by: bag)
        viewModel.isValidInput.subscribe(onNext: { [weak self] isValid in
            self?.btnLogin.backgroundColor = isValid ? .systemBlue : .systemRed
        }).disposed(by: bag)
    }
    
    
}

class LoginViewModel {
    var email: BehaviorSubject<String> = BehaviorSubject(value: "")
    var password: BehaviorSubject<String> = BehaviorSubject(value: "")
    
    var isValidEmail: Observable<Bool> {
        email.map{$0.isValidEmail() }
    }
    
    var isValidPassword: Observable<Bool> {
        password.map { password in
            return password.count < 6 ? false : true
        }
    }
    
    var isValidInput: Observable<Bool> {
        return Observable.combineLatest(isValidEmail, isValidPassword)
            .map({$0 && $1})
    }
    
    //Our viewmodel is ready
}

extension String {
    func isValidEmail() -> Bool {
        let regex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$", options: .caseInsensitive)
        return regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: count)) != nil
    }
}
