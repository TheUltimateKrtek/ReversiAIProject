//TODO: Touchscreen control
//TODO: animate

static public class TreeScreen{
  //Version 1.0.0
  private String name;
  
  private boolean isActive, isInitialized;
  
  private float positionX, positionY, rotation, scaleX, scaleY;
  private float alignX, alignY;
  private PMatrix2D localMatrix, globalMatrix, reversedLocalMatrix, reversedGlobalMatrix;
  private boolean needsLocalMatrixUpdate, needsGlobalMatrixUpdate;
  
  private TreeScreen parent;
  private ArrayList<TreeScreen> children;
  
  static private TreeScreen pressed, keyboard;
  static private float lastMousePressedX = Float.NaN, lastMousePressedY = Float.NaN, lastMouseX = Float.NaN, lastMouseY = Float.NaN;
  static private long lastMousePressedTime = 0, lastMouseTime = 0;
  private ArrayList<KeyboardCharacter> keyboardCharacters;
  
  private boolean createsOwnGraphics;
  private PGraphics ownGraphics;
  private int width, height;
  
  private long renderTime, childrenRenderTime;
  
  enum DestroyOperation{
    SUBTREE, SELF, CHILDREN
  }
  
  public static final class Cursor{
    public static final int ARROW = 0;
    public static final int CROSS = 1;
    public static final int HAND = 12;
    public static final int MOVE = 13;
    public static final int TEXT = 2;
    public static final int WAIT = 3;
  }
  
  //TODO: Remove unnecessary lines
  public final static TreeScreen ROOT = new TreeScreen("root", 0, 0, 0, 1, 1, 1, 1, 0, 0, false, false){
    protected void onDestroy(DestroyOperation type, TreeScreen parent){}
    protected void onActivated(){}
    protected void onDeactivated(){}
    protected void onAncestorActivated(TreeScreen ancestor){}
    protected void onAncestorDeactivated(TreeScreen ancestor){}
    
    protected void onUpdate(){}
    protected void onDraw(PGraphics pg){
      this.setGraphicsSize(pg.parent.width, pg.parent.height).setTransform(0, 0, 0, 1, 1).setAlign(0, 0);;
    }
    
    public boolean isPointPressable(float x, float y){return true;}
    public int onMouseCursorGet(float x, float y){return TreeScreen.Cursor.ARROW;}
    protected void onMousePressed(float x, float y){}
    protected void onMouseDragged(float x, float y, boolean outside){}
    protected void onMouseReleased(float x, float y, boolean outside){}
    protected void onMouseMoved(float x, float y){}
    protected void onMouseWheel(float x, float y, int value){}
    protected void onMouseInterupted(float x, float y){}
    
    protected void onKeyPressed(KeyboardCharacter c){}
    protected void onKeyReleased(KeyboardCharacter c){}
    protected void onKeyboardStarted(){}
    protected void onKeyboardEnded(){}
    protected void onKeyboardInterupted(KeyboardCharacter[] characters){}
    
    protected boolean canChildBeAdded(TreeScreen child, int index){return true;}
    protected boolean canChildBeRemoved(TreeScreen child, int index){return true;}
    protected boolean canChildChangeIndex(TreeScreen child, int previousindex, int index){return true;}
    protected boolean canParentBeSet(TreeScreen parent){return false;}
    protected boolean canParentBeRemoved(){return false;}
    
    protected boolean canTransformBeChanged(float px, float py, float r, float sx, float sy){return false;}
    protected boolean canSizeBeChanged(int w, int h){return true;}
    protected boolean canAlignBeChanged(float ax, float ay){return true;}
    
    
    protected void onTransformChanged(float px, float py, float r, float sx, float sy){}
    protected void onSizeChanged(int w, int h){}
    protected void onAlignChanged(float ax, float ay){}
    protected void onParentSet(){}
    protected void onParentRemoved(TreeScreen parent){}
    protected void onChildAdded(TreeScreen child, int index){}
    protected void onChildRemoved(TreeScreen child, int index){}
    protected void onChildIndexChanged(TreeScreen child, int previousindex, int index){}
    
  };
  
  public TreeScreen(String name, float px, float py, float r, float sx, float sy, int w, int h, float ax, float ay, boolean createOwnGraphics, boolean isKeyboardInteractable){
    this.children = new ArrayList<TreeScreen>();
    if(TreeScreen.ROOT != null){
      TreeScreen.ROOT.children.add(this);
      this.parent = TreeScreen.ROOT;
    }
    
    this.isActive = true;
    this.name = name == null ? "" : name;
    
    this.positionX = px;
    this.positionY = py;
    this.rotation = r;
    this.scaleX = sx;
    this.scaleY = sy;
    this.width = w < 1 ? 1 : w;
    this.height = h < 1 ? 1 : h;
    this.alignX = (float)Math.max(0, Math.min(1, ax));
    this.alignY = (float)Math.max(0, Math.min(1, ay));
    this.requestLocalMatrixUpdate();
    
    this.createsOwnGraphics = createOwnGraphics;
    if(isKeyboardInteractable) this.keyboardCharacters = new ArrayList<KeyboardCharacter>();
    
    this.isInitialized = true;
  }
  
  public final boolean isDestroyed(){
    return this.parent == null && this != TreeScreen.ROOT;
  }
  public final void destroy(){
    this.destroy(DestroyOperation.SUBTREE);
  }
  public final void destroy(DestroyOperation type){
    if(this == TreeScreen.ROOT) throw new RuntimeException("The root can't be destroyed");
    if(type == null) type = DestroyOperation.SUBTREE;
    if(this.isDestroyed()) return;
    
    TreeScreen parent = this.parent;
    if(type == DestroyOperation.SUBTREE){
      while(this.children.size() > 0) this.children.get(0).destroy(DestroyOperation.SUBTREE);
      this.interuptPressed();
      this.parent.children.remove(this);
      this.parent = null;
      this.onDestroy(type, parent);
    }
    else if(type == DestroyOperation.SELF){
      int childIndex = this.parent.indexOfChild(this);
      while(this.children.size() > 0){
        TreeScreen child = this.children.get(0);
        if(!child.canParentBeRemoved() ||
           !this.canChildBeRemoved(this, 0) ||
           !this.parent.canChildBeAdded(this, childIndex)){
          child.destroy(DestroyOperation.SUBTREE);
        }
        child.setParent(childIndex, this.parent);
        childIndex ++;
      }
      this.interuptPressed();
      this.parent.children.remove(this);
      this.parent = null;
      this.onDestroy(type, parent);
    }
    else if(type == DestroyOperation.CHILDREN){
      while(this.children.size() > 0){
        this.children.get(0).destroy(DestroyOperation.SUBTREE);
      }
    }
  }
  
  
  final public String getName(){
    return this == TreeScreen.ROOT ? "root" : this.name;
  }
  final public TreeScreen setName(String name){
    this.name = name == null ? "" : name;
    return this;
  }
  
  final public boolean isInitialized(){
    return this.isInitialized;
  }
  final public boolean isActive(){
    if(this == TreeScreen.ROOT) return true;
    if(this.isDestroyed()) return false;
    if(!this.isActive) return false;
    if(!this.isInitialized) return false;
    return this.parent.isActive();
  }
  final public TreeScreen setActive(boolean val){
    this.isActive = val;
    if(val) this.onActivated();
    if(!val) this.onDeactivated();
    
    if(this.isActive()){
      ArrayList<TreeScreen> notify = new ArrayList<TreeScreen>();
      for(TreeScreen child:this.children) notify.add(child);
      while(notify.size() > 0){
        TreeScreen descendant = notify.get(0);
        notify.remove(0);
        
        if(val) descendant.onAncestorActivated(this);
        else descendant.onAncestorDeactivated(this);
        
        if(!val && descendant.isPressed()) descendant.interuptPressed();
        
        if(!descendant.isActive) continue;
        for(int i = descendant.children.size() - 1; i >= 0; i ++){
          notify.add(descendant.children.get(i));
        }
      }
    }
    
    return this;
  }
  
  
  
  
  
  //---------------------
  //------TRANSFORM------
  //---------------------
  final public TreeScreen setTransform(float px, float py, float r, float sx, float sy){
    if(!this.isInitialized) return this;
    if(this.positionX != px || this.positionY != py || this.rotation != r || this.scaleX != sx || this.scaleY != sy){
      float ppx = this.positionX;
      float ppy = this.positionY;
      float pr = this.rotation;
      float psx = this.scaleX;
      float psy = this.scaleY;
      
      if(px == ppx && py == ppy && r == pr && sx == psx && sy == psy) return this;
      
      this.positionX = px;
      this.positionY = py;
      this.rotation = r;
      this.scaleX = sx;
      this.scaleY = sy;
      
      this.requestLocalMatrixUpdate();
      
      this.onTransformChanged(ppx, ppy, pr, psx, psy);
    }
    return this;
  }
  final public TreeScreen setPosition(float px, float py){
    if(!this.isInitialized) return this;
    if(this.positionX != px || this.positionY != py){
      float ppx = this.positionX;
      float ppy = this.positionY;
      float pr = this.rotation;
      float psx = this.scaleX;
      float psy = this.scaleY;
      
      if(px == ppx && py == ppy) return this;
      
      this.positionX = px;
      this.positionY = py;
      
      this.requestLocalMatrixUpdate();
      
      this.onTransformChanged(ppx, ppy, pr, psx, psy);
    }
    return this;
  }
  final public TreeScreen setRotation(float r){
    if(!this.isInitialized) return this;
    if(this.rotation != r){
      float ppx = this.positionX;
      float ppy = this.positionY;
      float pr = this.rotation;
      float psx = this.scaleX;
      float psy = this.scaleY;
      
      if(r == pr) return this;
      
      this.rotation = r;
      
      this.requestLocalMatrixUpdate();
      
      this.onTransformChanged(ppx, ppy, pr, psx, psy);
    }
    return this;
  }
  final public TreeScreen setScale(float sx, float sy){
    if(!this.isInitialized) return this;
    if(this.scaleX != sx || this.scaleY != sy){
      float ppx = this.positionX;
      float ppy = this.positionY;
      float pr = this.rotation;
      float psx = this.scaleX;
      float psy = this.scaleY;
      
      if(sx == psx && sy == psy) return this;
      
      this.scaleX = sx;
      this.scaleY = sy;
      
      this.requestLocalMatrixUpdate();
      
      this.onTransformChanged(ppx, ppy, pr, psx, psy);
    }
    return this;
  }
  final public float getPositionX(){
    return this.positionX;
  }
  final public float getPositionY(){
    return this.positionY;
  }
  final public float getRotation(){
    return this.rotation;
  }
  final public float getScaleX(){
    return this.scaleX;
  }
  final public float getScaleY(){
    return this.scaleY;
  }
  
  final public TreeScreen setAlign(float ax, float ay){
    if(!this.isInitialized) return this;
    if(this.isDestroyed()) return this;
    if(ax < 0 || ay < 0 || ax > 1 || ay > 1) throw new IllegalArgumentException("Width and height must be at least 1");
    if(this.alignX != ax || this.alignY != ay){
      float pax = this.width;
      float pay = this.height;
      
      this.alignX = ax;
      this.alignY = ay;
      
      this.requestLocalMatrixUpdate();
      
      this.onAlignChanged(pax, pay);
    }
    
    return this;
  }
  final public float getAlignX(){
    return this.alignX;
  }
  final public float getAlignY(){
    return this.alignY;
  }
  protected final void requestLocalMatrixUpdate(){
    this.needsLocalMatrixUpdate = true;
    this.requestGlobalMatrixUpdate();
  }
  protected final void requestGlobalMatrixUpdate(){
    if(this.needsGlobalMatrixUpdate) return;
    this.needsGlobalMatrixUpdate = true;
    for(TreeScreen child:this.children) child.requestGlobalMatrixUpdate();
  }
  private synchronized final void updateMatrices(){
    if(!this.isInitialized) return;
    if(this.isDestroyed()) return;
    if(this.needsLocalMatrixUpdate){
      PVector alignVector = new PVector(
        - this.alignX * this.width * this.scaleX,
        - this.alignY * this.height * this.scaleY
      );
      float sin = (float)Math.sin(this.rotation);
      float cos = (float)Math.cos(this.rotation);
      this.localMatrix = new PMatrix2D();
      this.localMatrix.translate(this.positionX, this.positionY);
      this.localMatrix.rotate(this.rotation);
      this.localMatrix.translate(alignVector.x, alignVector.y);
      this.localMatrix.scale(this.scaleX, this.scaleY);
      
      this.reversedLocalMatrix = new PMatrix2D(this.localMatrix);
      this.reversedLocalMatrix.invert();
      
      this.needsLocalMatrixUpdate = false;
    }
    if(this.needsGlobalMatrixUpdate){
      if(this == TreeScreen.ROOT){
        this.globalMatrix = new PMatrix2D(this.localMatrix);
      }
      else{
        this.parent.updateMatrices();
        this.globalMatrix = new PMatrix2D(this.parent.globalMatrix);
        this.globalMatrix.apply(this.localMatrix);
      }
      this.reversedGlobalMatrix = new PMatrix2D(this.globalMatrix);
      this.reversedGlobalMatrix.invert();
      
      this.needsGlobalMatrixUpdate = false;
    }
  }
  
  public final PVector localToGlobal(PVector v){
    if(!this.isInitialized) return null;
    if(v == null) return null;
    this.updateMatrices();
    return this.reversedGlobalMatrix.mult(v, null);
  }
  public final PVector localToGlobal(float x, float y){
    if(!this.isInitialized) return null;
    this.updateMatrices();
    return this.reversedGlobalMatrix.mult(new PVector(x, y), null);
  }
  public final PVector globalToLocal(PVector v){
    if(!this.isInitialized) return null;
    if(v == null) return null;
    this.updateMatrices();
    return this.globalMatrix.mult(v, null);
  }
  public final PVector globalToLocal(float x, float y){
    if(!this.isInitialized) return null;
    this.updateMatrices();
    return this.reversedGlobalMatrix.mult(new PVector(x, y), null);
  }
  public final boolean isGlobalPointInside(PVector v){
    if(!this.isInitialized) return false;
    return this.isLocalPointInside(this.globalToLocal(v));
  }
  public final boolean isGlobalPointInside(float x, float y){
    if(!this.isInitialized) return false;
    return this.isLocalPointInside(this.globalToLocal(x, y));
  }
  public final boolean isLocalPointInside(PVector v){
    if(!this.isInitialized) return false;
    if(v == null) return false;
    return v.x >= 0 && v.y >= 0 && v.x < this.width && v.y < this.height;
  }
  public final boolean isLocalPointInside(float x, float y){
    if(!this.isInitialized) return false;
    return x >= 0 && y >= 0 && x < this.width && y < this.height;
  }
  public final PMatrix2D getLocalMatrix(){
    if(!this.isInitialized) return null;
    this.updateMatrices();
    return new PMatrix2D(this.localMatrix);
  }
  public final PMatrix2D getReversedLocalMatrix(){
    if(!this.isInitialized) return null;
    this.updateMatrices();
    return new PMatrix2D(
      this.reversedLocalMatrix.m00, this.reversedLocalMatrix.m01, this.reversedLocalMatrix.m02,
      this.reversedLocalMatrix.m10, this.reversedLocalMatrix.m11, this.reversedLocalMatrix.m12
    );
  }
  public final PMatrix2D getGlobalMatrix(){
    if(!this.isInitialized) return null;
    this.updateMatrices();
    return new PMatrix2D(this.globalMatrix);
  }
  public final float[] getLocalBoundingBox(){
    if(!this.isInitialized) return null;
    this.updateMatrices();
    
    float[] rl = new float[]{Float.MAX_VALUE, Float.MAX_VALUE, Float.MIN_VALUE, Float.MIN_VALUE};
    
    float w = this.getGraphicsWidth();
    float h = this.getGraphicsHeight();
    
    PVector[] vs = new PVector[]{
      this.localMatrix.mult(new PVector(0, 0), null),
      this.localMatrix.mult(new PVector(w, 0), null),
      this.localMatrix.mult(new PVector(0, h), null),
      this.localMatrix.mult(new PVector(w, h), null)
    };
    
    for(int i = 0; i < 4; i ++){
      if(vs[i].x < rl[0]) rl[0] = vs[i].x;
      if(vs[i].y < rl[1]) rl[1] = vs[i].y;
      if(vs[i].x > rl[2]) rl[2] = vs[i].x;
      if(vs[i].y > rl[3]) rl[3] = vs[i].y;
    }
    
    return rl;
  }
  public final float[] getGlobalBoundingBox(){
    if(!this.isInitialized) return null;
    this.updateMatrices();
    
    float[] rl = new float[]{Float.MAX_VALUE, Float.MAX_VALUE, Float.MIN_VALUE, Float.MIN_VALUE};
    
    float w = this.getGraphicsWidth();
    float h = this.getGraphicsHeight();
    
    PVector[] vs = new PVector[]{
      this.globalMatrix.mult(new PVector(0, 0), null),
      this.globalMatrix.mult(new PVector(w, 0), null),
      this.globalMatrix.mult(new PVector(0, h), null),
      this.globalMatrix.mult(new PVector(w, h), null)
    };
    
    for(int i = 0; i < 4; i ++){
      if(vs[i].x < rl[0]) rl[0] = vs[i].x;
      if(vs[i].y < rl[1]) rl[1] = vs[i].y;
      if(vs[i].x > rl[2]) rl[2] = vs[i].x;
      if(vs[i].y > rl[3]) rl[3] = vs[i].y;
    }
    
    return rl;
  }
  
  
  
  
  //--------------------
  //--------TREE--------
  //--------------------
  final public TreeScreen getParent(){
    return this.parent;
  }
  final public TreeScreen setParent(int index, TreeScreen parent){
    if(!this.isInitialized) return null;
    if(this.isDestroyed()) return this;
    if(parent == null) parent = TreeScreen.ROOT;
    
    if(parent == this.parent){
      int currentIndex = this.parent.children.indexOf(this);
      if(currentIndex == index) return this;
      if(index < 0 || index >= this.parent.children.size()) throw new IndexOutOfBoundsException();
      if(!this.parent.canChildChangeIndex(this, currentIndex, index)) return this;
      
      this.parent.children.remove(currentIndex);
      this.parent.children.add(index, this);
      
      this.requestLocalMatrixUpdate();
      
      this.parent.onChildIndexChanged(this, currentIndex, index);
      
      return this;
    }
    else{
      if(parent.isDestroyed()) return this;
      if(index < 0 || index > parent.children.size()) throw new IndexOutOfBoundsException("Index: " + index + ", Size: " + parent.children.size());
      if(parent.containsChild(this)) return this;
      if(this.isAncestorOf(parent)) return this;
      
      int currentIndex = this.parent.children.indexOf(this);
      if(!this.canParentBeRemoved() || !this.parent.canChildBeRemoved(this, currentIndex) || !parent.canChildBeAdded(this, index)) return this;
      
      TreeScreen previousParent = this.parent;
      this.parent.children.remove(currentIndex);
      this.parent = parent;
      this.parent.children.add(index, this);
      
      this.requestLocalMatrixUpdate();
      
      previousParent.onChildRemoved(this, currentIndex);
      this.onParentRemoved(previousParent);
      this.parent.onChildAdded(this, index);
      this.onParentSet();
      
      return this;
    }
  }
  final public TreeScreen setParent(TreeScreen parent){
    int index = parent == null ? 0 : parent.children.size();
    return this.setParent(index, parent);
  }
  final public TreeScreen removeParent(){
    return this.setParent(0, null);
  }
  final public boolean containsChild(TreeScreen child){
    if(child == null) return false;
    return child.parent == this;
  }
  final public TreeScreen getChild(int index){
    if(index < 0 || index >= this.children.size()) throw new IndexOutOfBoundsException();
    return this.children.get(index);
  }
  final public int getChildCount(){
    return this.children.size();
  }
  final public TreeScreen[] getChildren(){
    TreeScreen[] rl = new TreeScreen[this.children.size()];
    for(int i = 0; i < rl.length; i ++) rl[i] = this.children.get(i);
    return rl;
  }
  final public int indexOfChild(TreeScreen child){
    return this.children.indexOf(child);
  }
  final public TreeScreen addChild(TreeScreen child){
    if(child == null) return this;
    child.setParent(this.children.size(), this);
    return this;
  }
  final public TreeScreen addChild(int index, TreeScreen child){
    if(child == null) return this;
    child.setParent(index, this);
    return this;
  }
  final public TreeScreen addChildren(TreeScreen... children){
    for(TreeScreen child:children) this.addChild(child);
    return this;
  }
  final public TreeScreen addChildren(int index, TreeScreen... children){
    for(int i = children.length - 1; i >= 0; i --) this.addChild(index, children[i]);
    return this;
  }
  final public TreeScreen removeChild(TreeScreen child){
    if(child == null) return this;
    if(!this.containsChild(child)) return this;
    child.setParent(0, null);
    return this;
  }
  final public TreeScreen removeChild(int index){
    if(index < 0 || index >= this.children.size()) throw new IndexOutOfBoundsException();
    this.children.get(index).setParent(0, null);
    return this;
  }
  final public TreeScreen removeChildren(TreeScreen... children){
    for(TreeScreen child:children) this.removeChild(child);
    return this;
  }
  //TODO: removeChildren(int index, int length)
  
  //FIXME: Optimize
  final public int getLevel(){
    if(this == TreeScreen.ROOT) return 0;
    return this.parent.getLevel() + 1;
  }
  final public int getDepth(){
    if(this.children.size() == 0) return 0;
    int max = 0;
    for(TreeScreen child:this.children){
      int depth = child.getDepth();
      if(depth > max) max = depth;
    }
    return max + 1;
  }
  final public boolean isAncestorOf(TreeScreen descendant){
    if(descendant == null) return false;
    if(descendant.isDestroyed()) return false;
    while(descendant != null){
      if(descendant == this) return true;
      descendant = descendant.getParent();
    }
    return false;
  }
  final public boolean isDescendantOf(TreeScreen ancestor){
    if(ancestor == null) return false;
    return ancestor.isAncestorOf(this);
  }
  final public TreeScreen[] getAncestors(){
    ArrayList<TreeScreen> ral = new ArrayList<TreeScreen>();
    TreeScreen screen = this;
    while((screen = this.getParent()) != null){
      ral.add(0, screen);
    }
    TreeScreen[] rl = new TreeScreen[ral.size()];
    for(int i = 0; i < rl.length; i ++) rl[i] = ral.get(i);
    return rl;
  }
  final public boolean isLeaf(){
    return this.children.size() == 0;
  }
  final public TreeScreen getMostRecentCommonAncestor(TreeScreen screen){
    if(screen == null) return null;
    if(screen.isDestroyed() || this.isDestroyed()) return null;
    
    TreeScreen[] screenAncestors = screen.getAncestors();
    TreeScreen[] thisAncestors = this.getAncestors();
    for(int i = Math.min(screenAncestors.length, thisAncestors.length) - 1; i >= 0; i ++){
      if(screenAncestors[i] == thisAncestors[i]) return screenAncestors[i];
    }
    return null;
  }
  final public TreeScreen[] search(int count, SearchFilter... filters){
    if(count < 1) return new TreeScreen[0];
    ArrayList<TreeScreen> check = new ArrayList<TreeScreen>();
    ArrayList<TreeScreen> ral = new ArrayList<TreeScreen>();
    check.add(this);
    
    while(check.size() != 0){
      TreeScreen current = check.get(0);
      check.remove(0);
      
      boolean valid = true;
      for(int i = 0; i < filters.length && valid; i ++){
        if(!filters[i].isValid(current)) valid = false;
      }
      
      if(valid) ral.add(current);
      
      for(int i = 0; i < current.children.size(); i ++){
        check.add(i, current.children.get(i));
      }
    }
    
    TreeScreen[] rl = new TreeScreen[ral.size()];
    for(int i = 0; i < rl.length; i ++) rl[i] = ral.get(i);
    return rl;
  }
  
  
  
  
  //---------------------
  //--MOUSE-INTERACTION--
  //---------------------
  final public boolean isPressed(){
    return TreeScreen.pressed == this;
  }
  final public TreeScreen getPressed(){
    return TreeScreen.pressed;
  }
  final public TreeScreen mousePressed(float x, float y){
    this.mousePressed(x, y, System.currentTimeMillis());
    return this;
  }
  final public boolean debugPressed(int x, int y){
    if(!this.isActive() || TreeScreen.pressed != null) return false;
    this.updateMatrices();
    PVector vector = this.globalToLocal(x, y);
    if(this != TreeScreen.ROOT){
      if(vector.x < 0 || vector.y < 0 || vector.x >= this.width || vector.y >= this.height) return false;
      if(!this.isPointPressable(vector.x, vector.y)) return false;
    }
    for(int i = this.children.size() - 1; i >= 0; i --){
      boolean pressed = this.children.get(i).debugPressed(x, y);
      if(pressed) return true;
    }
    
    return this != TreeScreen.ROOT;
  }
  final private boolean mousePressed(float x, float y, long time){
    if(!this.isActive() || TreeScreen.pressed != null) return false;
    if(this == TreeScreen.ROOT){
      for(int i = this.children.size() - 1; i >= 0; i --){
        boolean pressed = this.children.get(i).mousePressed(x, y, time);
        if(pressed) return true;
      }
      return false;
    }
    this.updateMatrices();
    PVector vector = this.globalToLocal(x, y);
    
    if(vector.x < 0 || vector.y < 0 || vector.x >= this.width || vector.y >= this.height) return false;
    if(!this.isPointPressable(vector.x, vector.y)) return false;
    
    for(int i = this.children.size() - 1; i >= 0; i --){
      boolean pressed = this.children.get(i).mousePressed(x, y, time);
      if(pressed) return true;
    }
    
    if(TreeScreen.keyboard != null) if(TreeScreen.keyboard != this) TreeScreen.keyboard.interuptKeyboard();
    
    TreeScreen.lastMousePressedX = x;
    TreeScreen.lastMousePressedY = y;
    TreeScreen.lastMousePressedTime = time;
    TreeScreen.lastMouseX = x;
    TreeScreen.lastMouseY = y;
    TreeScreen.lastMouseTime = time;
    
    this.onMousePressed(vector.x, vector.y);
    TreeScreen.pressed = this;
    return true;
  }
  final public TreeScreen mouseDragged(float x, float y){
    TreeScreen pressed = TreeScreen.pressed;
    if(pressed == null) return this;    
    long time = System.currentTimeMillis();
    pressed.updateMatrices();
    PVector vector = pressed.globalToLocal(x, y);
    
    pressed.onMouseDragged(vector.x, vector.y, pressed.isPointPressable(x, y));
    
    TreeScreen.lastMouseX = x;
    TreeScreen.lastMouseY = y;
    TreeScreen.lastMouseTime = time;
    
    return this;
  }
  final public TreeScreen mouseReleased(float x, float y){
    TreeScreen pressed = TreeScreen.pressed;
    if(pressed == null) return this;    
    pressed.updateMatrices();
    PVector vector = pressed.globalToLocal(TreeScreen.lastMouseX, TreeScreen.lastMouseY);
    TreeScreen.pressed = null;
    
    pressed.onMouseReleased(vector.x, vector.y, pressed.isPointPressable(x, y));
    
    TreeScreen.lastMousePressedX = Float.NaN;
    TreeScreen.lastMousePressedY = Float.NaN;
    TreeScreen.lastMousePressedTime = 0;
    TreeScreen.lastMouseX = Float.NaN;
    TreeScreen.lastMouseY = Float.NaN;
    TreeScreen.lastMouseTime = 0;
    
    return this;
  }
  final public boolean mouseMoved(float x, float y){
    return this.mouseMoved(x, y, true, true);
  }
  final public boolean mouseMoved(float x, float y, boolean globalMatrix, boolean recursion){
    if(!this.isActive()) return false;
    
    this.updateMatrices();
    PVector vector = this.globalMatrix.mult(new PVector(x, y), null);
    
    if(vector.x < 0 && vector.y < 0 && vector.x >= this.width && vector.y >= this.height) return false;
    if(!this.isPointPressable(vector.x, vector.y)) return false;
    for(int i = this.children.size() - 1; i >= 0; i ++){
      boolean pressed = this.children.get(i).mouseMoved(vector.x, vector.y, false, true);
      if(pressed) return true;
    }
    
    this.onMouseMoved(x, y);
    return true;
  }
  final public boolean mouseWheel(float x, float y, int value){
    return mouseWheel(x, y, value, true, true);
  }
  final public boolean mouseWheel(float x, float y, int value, boolean globalMatrix, boolean recursion){
    if(!this.isActive()) return false;
    
    this.updateMatrices();
    PVector vector = this.globalMatrix.mult(new PVector(x, y), null);
    
    if(vector.x < 0 && vector.y < 0 && vector.x >= this.width && vector.y >= this.height) return false;
    if(!this.isPointPressable(vector.x, vector.y)) return false;
    for(int i = this.children.size() - 1; i >= 0; i ++){
      boolean pressed = this.children.get(i).mouseMoved(vector.x, vector.y, false, true);
      if(pressed) return true;
    }
    
    this.onMouseWheel(x, y, value);
    return true;
  }
  //TODO: mouseWheel(float x, float y, int value){
  final public TreeScreen interuptPressed(){
    TreeScreen pressed = TreeScreen.pressed;
    if(pressed == null) return this;
    TreeScreen.pressed = null;
    
    this.updateMatrices();
    PVector vector = this.globalMatrix.mult(new PVector(TreeScreen.lastMouseX, TreeScreen.lastMouseY), null);
    
    pressed.onMouseInterupted(vector.x, vector.y);
    
    TreeScreen.lastMousePressedX = Float.NaN;
    TreeScreen.lastMousePressedY = Float.NaN;
    TreeScreen.lastMousePressedTime = 0;
    TreeScreen.lastMouseX = Float.NaN;
    TreeScreen.lastMouseY = Float.NaN;
    TreeScreen.lastMouseTime = 0;
    
    return this;
  }
  
  PVector getLastMousePressedCoordinates(){
    return new PVector(TreeScreen.lastMousePressedX, TreeScreen.lastMousePressedY);
  }
  long getLastMousePressedTime(){
    return TreeScreen.lastMousePressedTime;
  }
  PVector getLastMouseCoordinates(){
    return new PVector(TreeScreen.lastMouseX, TreeScreen.lastMouseY);
  }
  long getLastMouseTime(){
    return TreeScreen.lastMouseTime;
  }
  
  
  
  
  //----------------------
  //-KEYBOARD-INTERACTION-
  //----------------------
  public final KeyboardCharacter[] getKeyboardCharacters(){
    if(TreeScreen.keyboard != this) return null;
    KeyboardCharacter[] rl = new KeyboardCharacter[this.keyboardCharacters.size()];
    for(int i = 0; i < rl.length; i ++) rl[i] = this.keyboardCharacters.get(i);
    return rl;
  }
  public final TreeScreen keyPressed(char key, int keyCode){
    if(TreeScreen.keyboard == null) return this;
    if(TreeScreen.keyboard != this){
      TreeScreen.keyboard.keyPressed(key, keyCode);
      return this;
    }
    KeyboardCharacter c = new KeyboardCharacter(key, keyCode, System.currentTimeMillis());
    KeyboardCharacter found = null;
    int indexFound = -1;
    for(int i = 0; i < this.keyboardCharacters.size(); i ++){
      if(this.keyboardCharacters.get(i).equals(c)){
        found = this.keyboardCharacters.get(i);
        indexFound = i;
        break;
      }
    }
    if(found != null){
      this.keyboardCharacters.remove(indexFound);
      this.onKeyReleased(found);
    }
    
    this.keyboardCharacters.add(c);
    this.onKeyPressed(c);
    return this;
  }
  public final TreeScreen keyReleased(char key, int keyCode){
    if(TreeScreen.keyboard == null) return this;
    if(TreeScreen.keyboard != this){
      TreeScreen.keyboard.keyReleased(key, keyCode);
      return this;
    }
    KeyboardCharacter found = null;
    int indexFound = -1;
    for(int i = 0; i < this.keyboardCharacters.size(); i ++){
      if(this.keyboardCharacters.get(i).equals(key, keyCode)){
        found = this.keyboardCharacters.get(i);
        indexFound = i;
        break;
      }
    }
    if(found == null) return this;
    
    this.keyboardCharacters.remove(indexFound);
    this.onKeyReleased(found);
    return this;
  }
  public final TreeScreen startKeyboard(){
    if(!this.isKeyboardInteractable()) return this;
    if(TreeScreen.keyboard != null) TreeScreen.keyboard.interuptKeyboard();
    TreeScreen.keyboard = this;
    this.onKeyboardStarted();
    return this;
  }
  public final TreeScreen endKeyboard(){
    if(keyboard != this) return this;
    TreeScreen.keyboard = null;
    this.keyboardCharacters.clear();
    this.onKeyboardEnded();
    return this;
  }
  public final boolean hasKeyboard(){
    return TreeScreen.keyboard == this;
  }
  public final boolean isKeyboardInteractable(){
    return this.keyboardCharacters != null;
  }
  public static final TreeScreen getKeyboard(){
    return TreeScreen.keyboard;
  }
  public final TreeScreen interuptKeyboard(){
    if(TreeScreen.keyboard != this) return this;
    TreeScreen.keyboard = null;
    KeyboardCharacter[] chars = this.getKeyboardCharacters();
    this.keyboardCharacters.clear();
    this.onKeyboardInterupted(chars);
    return this;
  }
  
  //Android only
  final public TreeScreen backPressed(){
    if(TreeScreen.keyboard != null) TreeScreen.keyboard.interuptKeyboard();
    
    this.handleBackPressed();
    
    return this;
  }
  final private boolean handleBackPressed(){
    if(this.handlesBackPressed()){
      this.onBackPressed();
      return true;
    }
    
    for(int i = 0; i < this.children.size(); i ++){
      if(this.children.get(i).handleBackPressed()) return true;
    }
    
    return false;
  }
  
  
  
  //--------------------
  //------GRAPHICS------
  //--------------------
  final public TreeScreen setGraphicsSize(int w, int h){
    if(this.isDestroyed()) return this;
    
    //if(w < 1 || h < 1) throw new IllegalArgumentException("Width and height must be at least 1");
    if(w < 1) w = 1;
    if(h < 1) h = 1;
    if(this.width != w || this.height != h){
      int pw = this.width;
      int ph = this.height;
      
      this.width = w;
      this.height = h;
      
      this.requestLocalMatrixUpdate();
      
      this.onSizeChanged(pw, ph);
    }
    
    return this;
  }
  final public int getGraphicsWidth(){
    return this.width;
  }
  final public int getGraphicsHeight(){
    return this.height;
  }
  final public boolean createsOwnGraphics(){
    return this.createsOwnGraphics;
  }
  final public TreeScreen createsOwnGraphics(boolean val){
    if(this.createsOwnGraphics == val) return this;
    this.createsOwnGraphics = val;
    return this;
  }
  final public TreeScreen draw(PGraphics pg){
    if(!this.isActive()) return this;
    
    long time = System.nanoTime();
    if(pg == null) return this;
    if(this.createsOwnGraphics){
      this.updateMatrices();
      //TODO: Implement recycle graphics
      //      PGraphics.clear() doesn't work
      //      https://github.com/processing/processing4/blob/main/core/src/processing/core/PGraphics.java#L7629
      if(this.ownGraphics == null){
        this.ownGraphics = pg.parent.createGraphics(this.width, this.height);
      }
      if(this.width != this.ownGraphics.width || this.height != this.ownGraphics.height){
        this.ownGraphics = pg.parent.createGraphics(this.width, this.height);
      }
      
      this.onUpdate();
      this.ownGraphics.beginDraw();
      this.ownGraphics.clear();
      this.onUpdate();
      this.onDraw(pg);
      this.renderTime = System.nanoTime() - time;
      
      for(int i = 0; i < this.children.size(); i ++){
        this.children.get(i).draw(this.ownGraphics);
      }
      this.childrenRenderTime = System.nanoTime() - time;
      this.ownGraphics.endDraw();
      
      pg.pushMatrix();
      pg.applyMatrix(this.globalMatrix);
      pg.imageMode(CORNERS);
      pg.image(this.ownGraphics, 0, 0);
      pg.popMatrix();
      this.childrenRenderTime = System.nanoTime() - time;
    }
    else{
      this.updateMatrices();
      this.onUpdate();
      pg.pushMatrix();
      pg.applyMatrix(this.globalMatrix);
      this.onDraw(pg);
      pg.popMatrix();
      this.renderTime = System.nanoTime() - time;
      
      for(int i = 0; i < this.children.size(); i ++){
        this.children.get(i).draw(pg);
      }
      this.childrenRenderTime = System.nanoTime() - time;
    }
    
    return this;
  }
  public final long getRenderTime(){
    return this.renderTime;
  }
  public final long getChildrenRenderTime(){
    return this.childrenRenderTime;
  }
  
  
  
  //-------------------
  //-------DEBUG-------
  //-------------------
  public final void drawBoundingBoxes(PGraphics pg){
    this.drawBoundingBoxes(pg, this.getLevel());
  }
  private final void drawBoundingBoxes(PGraphics pg, int level){
    float h = (level * 30.0) % 255;
    
    //TODO: Implement code not dependant on pg.parent
    pg.parent.colorMode(HSB);
    int c = pg.parent.color(h, 255, 255);
    pg.parent.colorMode(RGB);
    
    float[] bb = this.getGlobalBoundingBox();
    pg.rectMode(CORNERS);
    pg.noFill();
    pg.stroke(c);
    pg.strokeWeight(3);
    pg.rect(bb[0], bb[1], bb[2], bb[3]);
    pg.fill(c);
    pg.textSize(20);
    pg.textAlign(LEFT, TOP);
    pg.text(this.getDebugText(), bb[0], bb[1]);
    
    for(int i = 0; i < this.children.size(); i ++){
      this.children.get(i).drawBoundingBoxes(pg, level + 1);
    }
  }
  public final String debugTree(){
    java.util.LinkedList<TreeScreen> check = new java.util.LinkedList<TreeScreen>();
    java.util.LinkedList<Integer> depths = new java.util.LinkedList<Integer>();
    int count = 1;
    check.push(this);
    depths.push(0);
    
    String rs = "";
    
    while(count > 0){
      count --;
      TreeScreen screen = check.pop();
      int depth = depths.pop();
      
      if(screen != this) rs += "\n";
      for(int i = 0; i < depth; i ++) rs += "    ";
      rs += screen.getDebugText();
      
      for(int i = 0; i < screen.getChildCount(); i ++){
        check.push(screen.getChild(i));
        depths.push(depth + 1);
        count ++;
      }
    }
    
    return rs;
  }
  public String getDebugText(){
    return this.getClass().getSimpleName() + " " + this.getName();
  }
  
  
  
  //--------------------
  //------ABSTRACT------
  //--------------------
  
  protected void onDestroy(DestroyOperation type, TreeScreen parent){}
  protected void onActivated(){}
  protected void onDeactivated(){}
  protected void onAncestorActivated(TreeScreen ancestor){}
  protected void onAncestorDeactivated(TreeScreen ancestor){}
  
  protected void onUpdate(){}
  protected void onDraw(PGraphics pg){}
  
  public boolean isPointPressable(float x, float y){return true;}
  public int onMouseCursorGet(float x, float y){return TreeScreen.Cursor.ARROW;}
  protected void onMousePressed(float x, float y){}
  protected void onMouseDragged(float x, float y, boolean inside){}
  protected void onMouseReleased(float x, float y, boolean inside){}
  protected void onMouseMoved(float x, float y){}
  protected void onMouseWheel(float x, float y, int value){}
  protected void onMouseInterupted(float x, float y){}
  
  protected void onKeyPressed(KeyboardCharacter c){}
  protected void onKeyReleased(KeyboardCharacter c){}
  protected void onKeyboardStarted(){}
  protected void onKeyboardEnded(){}
  protected void onKeyboardInterupted(KeyboardCharacter[] characters){}
  
  protected boolean canChildBeAdded(TreeScreen child, int index){return true;}
  protected boolean canChildBeRemoved(TreeScreen child, int index){return true;}
  protected boolean canChildChangeIndex(TreeScreen child, int previousindex, int index){return true;}
  protected boolean canParentBeSet(TreeScreen parent){return true;}
  protected boolean canParentBeRemoved(){return true;}
  
  protected boolean canTransformBeChanged(float px, float py, float r, float sx, float sy){return true;}
  protected boolean canSizeBeChanged(int w, int h){return true;}
  protected boolean canAlignBeChanged(float ax, float ay){return true;}
  
  protected void onTransformChanged(float px, float py, float r, float sx, float sy){}
  protected void onSizeChanged(int w, int h){}
  protected void onAlignChanged(float ax, float ay){}
  protected void onParentSet(){}
  protected void onParentRemoved(TreeScreen parent){}
  protected void onChildAdded(TreeScreen child, int index){}
  protected void onChildRemoved(TreeScreen child, int index){}
  protected void onChildIndexChanged(TreeScreen child, int previousindex, int index){}
  
  protected boolean handlesBackPressed(){return false;}
  protected void onBackPressed(){}
  
  private final class KeyboardCharacter{
    final char key;
    final int keyCode;
    final long time;
    
    public KeyboardCharacter(char key, int keyCode, long time){
      this.key = key;
      this.keyCode = keyCode;
      this.time = time;
    }
    
    public boolean equals(KeyboardCharacter c){
      if(c == null) return false;
      return this.key == c.key && this.keyCode == c.key;
    }
    public boolean equals(char key, int keyCode){
      return this.key == key && this.keyCode == key;
    }
  }
  
  private static abstract class SearchFilter{
    public abstract boolean isValid(TreeScreen screen);
  }
} 