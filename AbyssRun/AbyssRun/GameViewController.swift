import UIKit
import SpriteKit

final class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(skView)
        view.backgroundColor = .black

        // Present title scene
        let scene = TitleScene(size: CGSize(width: kSceneW, height: kSceneH))
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)

        skView.ignoresSiblingOrder = true
        // Uncomment for debugging:
        // skView.showsFPS = true
        // skView.showsPhysics = true
    }

    // Landscape only
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
}
