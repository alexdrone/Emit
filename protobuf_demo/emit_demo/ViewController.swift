import UIKit
import Emit
import SwiftProtobuf

class ViewController: UIViewController {

  @IBOutlet weak var label: UILabel!
  @IBOutlet weak var button: UIButton!

  let observableProto = ObservableProxy(buffer: BookInfo)

  override func viewDidLoad() {
    super.viewDidLoad()
    button.addTarget(self, action: #selector(buttonPressed(sender:)), for: .touchUpInside)
    observableProto.observeKeyPath(\BookInfo.author) { event in
      label.text = event.newValue
    }
  }

  private func buttonPressed(sender: UIButton) {
    observableProto.set(\BookInfo.author, "foo")
  }

}

