class FrameBuffer {
  final int width, height;
  late final int _frameBuffer;
  late final int _sourceTexture;

  int get sourceTexture => _sourceTexture;

  FrameBuffer(dynamic gl, this.width, this.height) {
    _frameBuffer = gl.createFramebuffer();
    gl.bindFramebuffer(gl.FRAMEBUFFER, _frameBuffer);

    final colorTexture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, colorTexture);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA,
        gl.UNSIGNED_BYTE, null);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, colorTexture, 0);

    final depthRBO = gl.createRenderbuffer();
    gl.bindRenderbuffer(gl.RENDERBUFFER, depthRBO);
    gl.renderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT16, width, height);
    gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, depthRBO);

    gl.bindFramebuffer(gl.FRAMEBUFFER, 0);

    _sourceTexture = colorTexture;
  }

  void bind(dynamic gl, Function f) {
    gl.bindFramebuffer(gl.FRAMEBUFFER, _frameBuffer);
    f();
    gl.bindFramebuffer(gl.FRAMEBUFFER, 0);
  }
}