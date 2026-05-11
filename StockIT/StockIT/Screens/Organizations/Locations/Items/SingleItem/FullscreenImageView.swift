import SwiftUI

struct ImageViewer<Content: View, Overlay: View>: View {
    var height: CGFloat
    var width: CGFloat
    @ViewBuilder var content: Content
    @ViewBuilder var overlay: Overlay
    var updates: (Bool, AnyHashable?) -> () = { _, _ in }

    @State private var isPresented: Bool = false
    @State private var activeTabID: Subview.ID?
    @State private var transitionSource: Int = 0
    @Namespace private var animation

    var body: some View {
        Group(subviews: content) { collection in
            TabView {
                ForEach(collection) { item in
                    let index = collection.index(item.id)

                    GeometryReader { geometry in
                        item
                            .aspectRatio(contentMode: .fill)
                            .frame(width: width, height: height)
                            .contentShape(.rect)
                            .onTapGesture {
                                activeTabID = item.id
                                isPresented = true
                                transitionSource = index
                            }
                           
                    }
                    .frame(height: height)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(width: width, height: height)
            .fullScreenCover(isPresented: $isPresented) {
                TabView(selection: $activeTabID) {
                    ForEach(collection) { item in
                        ZoomableImageView {
                            item
                        }
                        .tag(item.id)
                    }
                }
                .tabViewStyle(.page)
                .background {
                    Rectangle()
                        .fill(.black)
                        .ignoresSafeArea()
                }
                .overlay {
                    overlay
                }
                .navigationTransition(.zoom(sourceID: transitionSource, in: animation))
                .toolbarVisibility(.hidden, for: .navigationBar)
            }
            .onChange(of: activeTabID) { oldValue, newValue in
                transitionSource = min(collection.index(newValue), 3)
                sendUpdate(collection, id: newValue)
            }
            .onChange(of: isPresented) { oldValue, newValue in
                sendUpdate(collection, id: activeTabID)
            }
        }
    }

    private func sendUpdate(_ collection: SubviewsCollection, id: Subview.ID?) {
        if let viewID = collection.first(where: { $0.id == id })?.containerValues.activeViewID {
            updates(isPresented, viewID)
        }
    }
}

extension ContainerValues {
    @Entry var activeViewID: AnyHashable?
}

extension SubviewsCollection {
    func index(_ id: SubviewsCollection.Element.ID?) -> Int {
        firstIndex(where: { $0.id == id }) ?? 0
    }
}


struct OverlayView: View {
    var activeID: String?
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(.white.secondary)
                    .padding(10)
                    .contentShape(.rect)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 0)
        }
        .padding(15)
    }
}

struct ZoomableImageView<Content: View>: View {
    @ViewBuilder var content: Content

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var gestureOffset: CGSize = .zero

    var body: some View {
        content
            .aspectRatio(contentMode: .fit)
            .scaleEffect(scale * gestureScale)
            .offset(x: offset.width + gestureOffset.width, y: offset.height + gestureOffset.height)
            .gesture(
                MagnificationGesture()
                    .updating($gestureScale) { value, state, _ in
                        state = value
                    }
                    .onEnded { value in
                        scale *= value
                        if scale < 1 { scale = 1 }
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .updating($gestureOffset) { value, state, _ in
                        if scale > 1 {
                            state = value.translation
                        }
                    }
                    .onEnded { value in
                        if scale > 1 {
                            offset.width += value.translation.width
                            offset.height += value.translation.height
                        }
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation {
                    if scale > 1 {
                        scale = 1
                        offset = .zero
                    } else {
                        scale = 2
                    }
                }
            }
            .animation(.easeInOut, value: scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
