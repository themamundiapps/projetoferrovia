# Tira o cursor do modo gravação dos quadros: acha a seta por modelo e preenche com inpaint.
import cv2, numpy as np
from PIL import Image
FR = "/home/claude/video/frames"
_t = cv2.imread(f"{FR}/h14/%05d.jpg" % 121, cv2.IMREAD_GRAYSCALE)[650:678, 1036:1058]
_t2 = cv2.imread(f"{FR}/h15/%05d.jpg" % 121, cv2.IMREAD_GRAYSCALE)[650:676, 1002:1022]
def limpo(s, t, limiar=0.6):
    bgr = cv2.imread(f"{FR}/{s}/%05d.jpg" % (int(t * 30) + 1))
    g = cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)
    melhor = None
    for tp in (_t, _t2):
        r = cv2.matchTemplate(g, tp, cv2.TM_CCOEFF_NORMED)
        _, v, _, (x, y) = cv2.minMaxLoc(r)
        if melhor is None or v > melhor[0]: melhor = (v, x, y, tp)
    v, x, y, tp = melhor
    if v >= limiar:
        m = np.zeros(g.shape, np.uint8); m[y - 3:y + tp.shape[0] + 3, x - 3:x + tp.shape[1] + 3] = 255
        bgr = cv2.inpaint(bgr, m, 5, cv2.INPAINT_TELEA)
    limpo.ultimo = (v, x, y)
    return Image.fromarray(cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB))
