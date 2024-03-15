static class Rect{
  float x1, y1, x2, y2;
  
  public Rect(float x1, float y1, float x2, float y2){
    this.x1 = x1;
    this.y1 = y1;
    this.x2 = x2;
    this.y2 = y2;
  }
  
  public Rect translate(float x, float y){
    this.x1 += x;
    this.y1 += y;
    this.x2 += x;
    this.y2 += y;
    return this;
  }
  
  final public Rect set(float x1, float y1, float x2, float y2){
    this.x1 = x1;
    this.y1 = y1;
    this.x2 = x2;
    this.y2 = y2;
    return this;
  }
  final public Rect set(Rect rect){
    if(rect == null) return this;
    this.x1 = rect.x1;
    this.y1 = rect.y1;
    this.x2 = rect.x2;
    this.y2 = rect.y2;
    return this;
  }
  final public float getLeft(){
    return (float)Math.min(this.x1, this.x2);
  }
  final public float getRight(){
    return (float)Math.max(this.x1, this.x2);
  }
  final public float getTop(){
    return (float)Math.min(this.y1, this.y2);
  }
  final public float getBottom(){
    return (float)Math.max(this.y1, this.y2);
  }
  final public float getCenterX(){
    return (this.x1 + this.x2) * 0.5;
  }
  final public float getCenterY(){
    return (this.y1 + this.y2) * 0.5;
  }
  final public float getWidth(){
    return (float)Math.abs(this.x1 - this.x2);
  }
  final public float getHeight(){
    return (float)Math.abs(this.y1 - this.y2);
  }
  
  final public boolean isPointInside(float x, float y){
    float left = this.getLeft();
    float right = this.getRight();
    float top = this.getTop();
    float bottom = this.getBottom();
    return x >= left && x <= right && y >= top && y <= bottom;
  }
  
  final public Rect fitRectangle(float x, float y){
    float scale = (float)Math.min(this.getWidth() / x, this.getHeight() / y);
    
    float cx = this.getCenterX();
    float cy = this.getCenterY();
    float sx = x * scale * 0.5;
    float sy = y * scale * 0.5;
    
    return new Rect(cx - sx, cy - sy, cx + sx, cy + sy);
  }
  
  final public Rect[][] split(int x, int y){
    if(x <= 0 || y <= 0) throw new IllegalArgumentException();
    float left = this.getLeft();
    float top = this.getTop();
    float stepX = this.getWidth() / x;
    float stepY = this.getHeight() / y;
    float[] cxs = new float[x + 1];
    for(int i = 0; i < cxs.length; i ++) cxs[i] = left + stepX * i / x;
    float[] cys = new float[y + 1];
    for(int i = 0; i < cys.length; i ++) cys[i] = top + stepY * i / y;
    
    Rect[][] rl = new Rect[y][x];
    for(int yi = 0; yi < y; y ++){
      for(int xi = 0; xi < x; xi ++){
        rl[yi][xi] = new Rect(cxs[xi], cys[yi], cxs[xi + 1], cys[yi + 1]);
      }
    }
    
    return rl;
  }
  
  public final Rect scale(float s){
    return this.scale(s, s, 0.5, 0.5);
  }
  public final Rect scale(float x, float y){
    return this.scale(x, y, 0.5, 0.5);
  }
  public final Rect scale(float s, float ax, float ay){
    return this.scale(s, s, ax, ax);
  }
  public final Rect scale(float x, float y, float ax, float ay){
    float cx = this.getLeft() + this.getWidth() * ax;
    float cy = this.getTop() + this.getHeight() * ay;
    float left = this.getLeft() - cx;
    float top = this.getTop() - cy;
    float right = this.getRight() - cx;
    float bottom = this.getBottom() - cy;
    return this.set(cx + left * x, cy + top * x, cx + right * x, cy + bottom * y);
  }
  public final Rect scaleTowards(float s, float xp, float yp){
    return this.scaleTowards(s, s, xp, yp);
  }
  public final Rect scaleTowards(float x, float y, float xp, float yp){
    float left = this.getLeft() - xp;
    float top = this.getTop() - yp;
    float right = this.getRight() - xp;
    float bottom = this.getBottom() - yp;
    return this.set(left * x + xp, top * y + yp, right * x + xp, bottom * y + yp);
  }
  
  public final Rect copyRect(){
    return new Rect(this.x1, this.y1, this.x2, this.y2);
  }
}