//
//  File.swift
//  
//
//  Created by Macintosh on 25/01/21.
//

import UIKit

public class ResultController: UIViewController {
    private var image: UIImage!
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var completion: ((UIImage)->Void)?
    
    public init(with image: UIImage, completion: ((UIImage)->Void)?) {
        super.init(nibName: nil, bundle: nil)
        
        self.image = image
        self.completion = completion
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.image = image
        view.backgroundColor = .black
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(onTapDone(_:)))
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.addSubview(imageView)
        imageView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        imageView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    @objc
    private func onTapDone(_ sender: UIButton) {
        completion?(image)
    }
}
