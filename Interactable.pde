static abstract public class Interactable extends Rect{
  static final private ArrayList<Interactable> instances = new ArrayList<Interactable>();
  static private Interactable interactingWithKeyboard;
  static private Interactable pressed;
  
  private String name;
  private boolean isActive, isDestroyed;
  
  private boolean isPressed;
  
  private ArrayList<Interactable> children;
  private Interactable parent;
  
  public static final class Cursor{
    public static final int ARROW = 0;
    public static final int CROSS = 1;
    public static final int HAND = 12;
    public static final int MOVE = 13;
    public static final int TEXT = 2;
    public static final int WAIT = 3;
  }
  
  public Interactable(float x1, float y1, float x2, float y2, String name){
    super(x1, y1, x2, y2);
    this.setName(name);
    this.isActive = true;
    
    this.children = new ArrayList<Interactable>();
    
    this.isDestroyed = false;
    Interactable.instances.add(this);
  }
  
  public Interactable destroy(){
    println(this.name + " destroyed.");
    synchronized(Interactable.instances){
      if(this.isDestroyed) return this;
      for(int i = 0; i < this.children.size(); i ++){
        this.children.get(i).destroy();
      }
      this.children.clear();
      this.preDestroy();
      Interactable.instances.remove(this);
      this.interuptPressed();
      this.interuptInteractingWithKeyboard();
      this.isActive = false;
      this.isDestroyed = true;
      return this;
    }
  }
  public final boolean isDestroyed(){
    return this.isDestroyed;
  }
  
  public final static Interactable[] get(){
    synchronized(Interactable.instances){
      Interactable[] rl = new Interactable[Interactable.instances.size()];
      for(int i = 0; i < rl.length; i ++) rl[i] = Interactable.instances.get(i);
      return rl;
    }
  }
  public final static Interactable get(String name){
    synchronized(Interactable.instances){
      for(Interactable i:Interactable.instances){
        if(i.name.equals(name)) return i;
      }
      return null;
    }
  }
  public final static Interactable get(int index){
    synchronized(Interactable.instances){
      if(index < 0 || index >= Interactable.instances.size()) return null;
      return Interactable.instances.get(index);
    }
  }
  public final static Interactable get(String name, int index){
    synchronized(Interactable.instances){
      for(Interactable i:Interactable.instances){
        if(i.name.equals(name)) index --;
        if(index == 0) return i;
      }
      return null;
    }
  }
  public final static int size(){
    return Interactable.instances.size();
  }
  final public static void clear(){
    synchronized(Interactable.instances){
      while(Interactable.instances.size() > 0){
        Interactable.instances.get(0).destroy();
      }
    }
  }
  
  final public static Interactable getPressed(){
    return Interactable.pressed;
  }
  final public static boolean mousePressed(float x, float y){
    synchronized(Interactable.instances){
      for(int i = Interactable.instances.size() - 1; i >= 0; i --){
        Interactable interactable = Interactable.instances.get(i);
        if(!interactable.isActive || !interactable.isPointInside(x, y)) continue;
        if(Interactable.interactingWithKeyboard != null && Interactable.interactingWithKeyboard != interactable){
          Interactable.interactingWithKeyboard.onMousePressedOutsideWhileInteractingWithKeyboard();
        }
        Interactable.pressed = interactable;
        if(interactable.onMousePressed(x - interactable.getLeft(), y - interactable.getTop())){
          return true;
        }
      }
      return false;
    }
  }
  final public static void mouseDragged(float x, float y){
    synchronized(Interactable.instances){
      if(Interactable.pressed == null) return;
      Interactable.pressed.onMouseDragged(x - Interactable.pressed.getLeft(), y - Interactable.pressed.getTop());
    }
  }
  final public static void mouseReleased(){
    synchronized(Interactable.instances){
      if(Interactable.pressed == null) return;
      Interactable pressed = Interactable.pressed;
      Interactable.pressed = null;
      pressed.onMouseReleased();
    }
  }
  final public static void mouseMoved(float x, float y){
    synchronized(Interactable.instances){
      for(int i = Interactable.instances.size() - 1; i >= 0; i --){
        Interactable interactable = Interactable.instances.get(i);
        if(!interactable.isActive || !interactable.isPointInside(x, y)) continue;
        interactable.onMouseMoved(x - interactable.getLeft(), y - interactable.getTop());
        break;
      }
    }
  }
  final public static int hoverMouseIcon(float x, float y){
    synchronized(Interactable.instances){
      for(int i = Interactable.instances.size() - 1; i >= 0; i --){
        Interactable interactable = Interactable.instances.get(i);
        if(!interactable.isActive || !interactable.isPointInside(x, y)) continue;
        return interactable.getHoverCursorIcon(x - interactable.getLeft(), y - interactable.getTop());
      }
      return Cursor.ARROW;
    }
  }
  final public static void clearInteractingWithKeyboard(){
    if(Interactable.interactingWithKeyboard == null) return;
    Interactable.interactingWithKeyboard.endInteractingWithKeyboard();
  }
  final public static Interactable getInteractingWithKeyboard(){
    return Interactable.interactingWithKeyboard;
  }
  final public static void keyPressed(char key, int keyCode){
    if(Interactable.interactingWithKeyboard == null) return;
    Interactable.interactingWithKeyboard.onKeyPressed(key, keyCode);
  }
  final public static void keyReleased(char key, int keyCode){
    if(Interactable.interactingWithKeyboard == null) return;
    Interactable.interactingWithKeyboard.onKeyReleased(key, keyCode);
  }
  final public static void draw(PGraphics pg){
    if(pg == null) return;
    synchronized(Interactable.instances){
      for(int index = 0; index < Interactable.instances.size(); index ++){
        Interactable i = Interactable.instances.get(index);
        if(!i.isActive()) return;
        i.onUpdate();
        i.onDraw(pg);
      }
    }
  }
  final public void setInteractableInstanceIndex(int index){
    if(this.isDestroyed()) return;
    synchronized(Interactable.instances){
      if(index < 0 || index >= Interactable.instances.size()) throw new IndexOutOfBoundsException();
      Interactable.instances.remove(this);
      Interactable.instances.add(index, this);
    }
  }
  final public int getInteractableInstanceIndex(){
    if(this.isDestroyed()) return -1;
    return Interactable.instances.indexOf(this);
  }
  
  
  final public String getName(){
    return this.name;
  }
  final public Interactable setName(String name){
    this.name = name == null ? "" : name;
    return this;
  }
  
  final Interactable setParent(Interactable parent){
    return this.setParent(parent, parent == null ? 0 : parent.children.size());
  }
  final Interactable setParent(Interactable parent, int index){
    Interactable currentParent = this.parent;
    
    if(parent == null){
      if(this.parent != null){
        //Remove parent
        if(!this.parent.canChildBeRemoved(this) || !this.canParentBeRemoved()) return this;
        int childIndex = this.parent.children.indexOf(this);
        this.parent.children.remove(childIndex);
        this.parent = null;
        currentParent.onChildRemoved(this, childIndex);
        this.onParentSet(currentParent);
      }
    }
    else{
      if(parent.isDestroyed()) return this;
      if(this.isAncestorOf(parent)) return this;
      index = index < 0 ? 0 : (index > parent.children.size() ? parent.children.size() : index);
      if(this.parent == null){
        //Set parent
        if(!parent.canChildBeAdded(this, index) || !this.canParentBeSet(parent)) return this;
        this.parent = parent;
        this.parent.children.add(index, this);
        this.parent.onChildAdded(this, index);
        this.onParentSet(currentParent);
      }
      else{
        if(!this.parent.canChildBeRemoved(this) || !this.canParentBeRemoved()) return this;
        if(!this.parent.canChildBeAdded(this, index) || !this.canParentBeSet(parent)) return this;
        int childIndex = this.parent.children.indexOf(this);
        this.parent.children.remove(this);
        this.parent = parent;
        this.parent.children.add(index, this);
        currentParent.onChildRemoved(this, childIndex);
        this.parent.onChildAdded(this, index);
        this.onParentSet(currentParent);
      }
    }
    return this;
  }
  final public Interactable getParent(){
    return this.parent;
  }
  final public Interactable[] getChildren(){
    Interactable[] rl = new Interactable[this.children.size()];
    for(int i = 0; i < rl.length; i ++) rl[i] = this.children.get(i);
    return rl;
  }
  final public Interactable getChild(int index){
    if(index < 0 || index >= this.children.size()) throw new IndexOutOfBoundsException();
    return this.children.get(index);
  }
  final Interactable addChild(Interactable child){
    return this.addChild(this.children.size(), child);
  }
  final Interactable addChild(int index, Interactable child){
    if(child == null) return this;
    child.setParent(this, index);
    return this;
  }
  final Interactable removeChild(int index){
    if(index < 0 || index >= this.children.size()) throw new IndexOutOfBoundsException();
    this.children.get(index).setParent(null);
    return this;
  }
  final Interactable removeChild(Interactable child){
    if(this.children.contains(child)) child.setParent(null);
    return this;
  }
  final Interactable removeParent(){
    return this.setParent(null);
  }
  final boolean isRoot(){
    return this.parent != null;
  }
  final boolean isLeaf(){
    return this.children.size() == 0;
  }
  final int getChildCount(){
    return this.children.size();
  }
  final int getLevel(){
    return this.parent == null ? 0 : (this.parent.getLevel() + 1);
  }
  final int getDepth(){
    if(this.isLeaf()) return 0;
    int max = 0;
    for(int i = 0; i < this.children.size(); i ++){
      int depth = this.children.get(i).getDepth();
       max = Math.max(depth, max);
    }
    return max + 1;
  }
  final boolean isAncestorOf(Interactable child){
    //TODO: Optimize; see canBeAddedAsParent(Transform)
    Interactable root = child;
    while(root != null){
      root = root.getParent();
      if(root == child) return true;
    }
    return false;
  }
  final Interactable getRoot(){
    Interactable root = this;
    while(!root.isRoot()) root = root.getParent();
    return root;
  }
  
  
  final public boolean isActive(){
    if(this.parent == null) return this.isActive;
    return this.parent.isActive();
  }
  final public Interactable setActive(boolean isActive){
    this.isActive = isActive;
    if(!this.isActive){
      this.interuptPressed();
      this.interuptInteractingWithKeyboard();
    }
    return this;
  }
  
  final public boolean isPressed(){
    return Interactable.pressed == this;
  }
  final public boolean isInteractingWithKeyboard(){
    return Interactable.interactingWithKeyboard == this;
  }
  final public Interactable interuptPressed(){
    if(!this.isActive || this.isDestroyed) return this;
    if(Interactable.pressed != this) return this;
    Interactable.pressed = null;
    this.onPressedInterupted();
    return this;
  }
  final public Interactable startInteractingWithKeyboard(){
    if(!this.isActive || this.isDestroyed) return this;
    if(Interactable.interactingWithKeyboard == this) return this;
    if(Interactable.interactingWithKeyboard != null) Interactable.interactingWithKeyboard.endInteractingWithKeyboard();
    Interactable.interactingWithKeyboard = this;
    this.onInteractionWithKeyboardStarted();
    return this;
  }
  final public Interactable endInteractingWithKeyboard(){
    if(Interactable.interactingWithKeyboard != this) return this;
    Interactable.interactingWithKeyboard = null;
    this.onInteractionWithKeyboardEnded();
    return this;
  }
  final public Interactable interuptInteractingWithKeyboard(){
    if(Interactable.interactingWithKeyboard != this) return this;
    Interactable.interactingWithKeyboard = null;
    this.onInteractionWithKeyboardInterupted();
    return this;
  }
  
  abstract protected void preDestroy();
  abstract protected boolean onMousePressed(float x, float y);
  abstract protected void onMouseDragged(float x, float y);
  abstract protected void onMouseReleased();
  abstract protected void onMouseMoved(float x, float y);
  abstract protected void onPressedInterupted();
  abstract protected void onKeyPressed(char key, int keyCode);
  abstract protected void onKeyReleased(char key, int keyCode);
  abstract protected void onInteractionWithKeyboardStarted();
  abstract protected void onInteractionWithKeyboardEnded();
  abstract protected void onInteractionWithKeyboardInterupted();
  abstract protected void onMousePressedOutsideWhileInteractingWithKeyboard();
  abstract protected int getHoverCursorIcon(float x, float y);
  abstract protected void onUpdate();
  abstract protected void onDraw(PGraphics pg);
  abstract protected boolean canParentBeSet(Interactable parent);
  abstract protected boolean canChildBeAdded(Interactable child, int index);
  abstract protected void onParentSet(Interactable previousParent);
  abstract protected void onChildAdded(Interactable child, int index);
  abstract protected boolean canChildChangeIndex(Interactable child, int prevIndex, int newIndex);
  abstract protected void onChildIndexChanged(int prevoiusIndex, int index);
  abstract protected boolean canParentBeRemoved();
  abstract protected boolean canChildBeRemoved(Interactable child);
  abstract protected void onChildRemoved(Interactable child, int index);
}