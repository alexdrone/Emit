import UIKit
import Emit
import SwiftProtobuf

class ViewController: UIViewController {

  @IBOutlet weak var label: UILabel!
  @IBOutlet weak var button: UIButton!
  var token: Observer?

  let observableProto = ObservableProxy(buffer: BookInfo())

  override func viewDidLoad() {
    super.viewDidLoad()
    button.addTarget(self, action: #selector(buttonPressed(sender:)), for: .touchUpInside)
    token = observableProto.observeKeyPath(keyPath: \BookInfo.author) { event in
      self.label.text = event.newValue
    }
  }

  @objc private func buttonPressed(sender: UIButton) {
    observableProto.set(\BookInfo.author, "foo")
  }

}

