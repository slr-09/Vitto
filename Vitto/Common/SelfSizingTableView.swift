import UIKit

final class SelfSizingTableView: UITableView {

    override var contentSize: CGSize {
        didSet {
            if intrinsicContentSize != oldValue {
                invalidateIntrinsicContentSize()
            }
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}
