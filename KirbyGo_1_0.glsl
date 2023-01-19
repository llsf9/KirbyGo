//utils
// Smooth Min
float smin( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return min(a, b) - h*h*0.25/k;
}

vec2 smin( vec2 a, vec2 b, float k )
{
    float h = clamp( 0.5+0.5*(b.x-a.x)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

//Smooth Max ; 实现缺口
float smax( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*0.25/k;
}

vec4 opU( vec4 d1, vec4 d2 )
{
	return (d1.x<d2.x) ? d1 : d2;
}

mat2 rotMat(float rot)
{
    float cc = cos(rot);
    float ss = sin(rot);
    return mat2(cc, ss, -ss, cc);
}

///////////////////////////////////
//sdf
float sdTorus(vec3 p, vec2 t) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdDonut(vec3 p, float rad) {
    float d1 = sdTorus(p, vec2(rad, rad/1.5));
	return d1;
}

float sdCream(vec3 p, float rad) {
    float f = 0.0;
    f += sin(p.x * 1.1*16. + p.z * 1.2*3.) * 1.;
    f += sin(p.x * 2.5*3.) * 0.5;
    f += sin(p.z * 4.*3.) * 0.25;
    f /= 8.0;
    
    float d2 = abs(p.y*7. + f + 2.0) - 2.3;
    
    float d1 = sdDonut(p,  rad);
    float d = max(d1, -d2);
    
	return d ;
}

//球
float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

//椭圆
float sdEllipsoid( in vec3 p, in vec3 r )
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

//棍
vec2 sdStick(vec3 p, vec3 a, vec3 b, float r1, float r2)
{
    vec3 pa = p-a, ba = b-a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return vec2( length( pa - ba*h ) - mix(r1,r2,h*h*(3.0-2.0*h)), h );
}

float sdEllipse( in vec2 p, in vec2 ab )
{
    p = abs(p); if( p.x > p.y ) {p=p.yx;ab=ab.yx;}
    float l = ab.y*ab.y - ab.x*ab.x;
    float m = ab.x*p.x/l;      float m2 = m*m; 
    float n = ab.y*p.y/l;      float n2 = n*n; 
    float c = (m2+n2-1.0)/3.0; float c3 = c*c*c;
    float q = c3 + m2*n2*2.0;
    float d = c3 + m2*n2;
    float g = m + m*n2;
    float co;
    if( d<0.0 )
    {
        float h = acos(q/c3)/3.0;
        float s = cos(h);
        float t = sin(h)*sqrt(3.0);
        float rx = sqrt( -c*(s + t + 2.0) + m2 );
        float ry = sqrt( -c*(s - t + 2.0) + m2 );
        co = (ry+sign(l)*rx+abs(g)/(rx*ry)- m)/2.0;
    }
    else
    {
        float h = 2.0*m*n*sqrt( d );
        float s = sign(q+h)*pow(abs(q+h), 1.0/3.0);
        float u = sign(q-h)*pow(abs(q-h), 1.0/3.0);
        float rx = -s - u - c*4.0 + 2.0*m2;
        float ry = (s - u)*sqrt(3.0);
        float rm = sqrt( rx*rx + ry*ry );
        co = (ry/sqrt(rm-rx)+2.0*g/rm-m)/2.0;
    }
    vec2 r = ab * vec2(co, sqrt(1.0-co*co));
    return length(r-p) * sign(p.y-r.y);
}

////////////////////////////////
//绘制物体
vec4 map( in vec3 pos, float atime )
{
    
    vec2 objXY = vec2(0.,0.);
    vec4 res = vec4(-1.,-1., objXY);
    
    //yMove
    float t = fract(atime); //[0,1]的上下波动函数
    float bounceWave = 4.0*t*(1.0-t);  //对t进行了曲线化，为了制作球体的上下跳动
    float yMove = pow(bounceWave,2.0-bounceWave) + 0.1; //下快上慢
    
    //zMove
    float zMove = floor(atime) + pow(t,0.7) -1.0 ; //非线性的smooth移动
        
     //xMove
    float tt = abs(fract(atime*0.5)-0.5)/0.5;
    float xMove = 0.5*(-1.0 + 2.0*tt);
     
    vec3 cen = vec3( xMove, yMove, zMove);//导入函数，画出球心的跳动感
    
    //Coordinate
    vec3 basic = pos-cen; 
    basic.xy = rotMat(-xMove*0.3) * basic.xy; 
    
    float ttt = abs(fract((atime+0.5)*0.5)-0.5)/0.5;
    float bodyMove = 0.5*(-1.0 + 2.0*ttt);
    basic.xz = rotMat(bodyMove*1.) * basic.xz;
    
    vec3 symmBody =  vec3(  abs(basic.x), basic.yz);
 
    
    //body: 尝试了形变效果，Q弹效果
    float sy = 0.9 + 0.1*bounceWave;
    float compress = 1.0-smoothstep(0.0,0.4,bounceWave);
    sy = sy*(1.0-compress) + compress;
    float sx = 1./sy;
    
    //float dBody = sdEllipsoid( basic , vec3(0.2*sx, 0.2*sy, 0.2) );
    float dBody = sdEllipsoid( basic , vec3(0.2, 0.2, 0.2) );

    //arm
    vec3 armPos = vec3(0.2, 0., 0.);
    float dArm = sdSphere( symmBody - armPos, 0.07);
    
    dBody = smin(dBody, dArm, 0.03);
    
    //mouth
    {
    float smell = 23.* basic.x*basic.x;
    vec3 mouthPos = vec3(0., -0.03 +smell, 0.17);
    float dMouth = sdEllipsoid( basic - mouthPos, vec3(0.1, 0.11, 0.15)*0.3 );
    
    dBody = smax(dBody, -dMouth, 0.01);
   
   vec2 frontBody= vec2(-1., -1.);    
    if (basic.z > 0.){frontBody = symmBody.xy;}

    vec4 bodyObj = vec4(dBody, 2.0, frontBody);
    res = bodyObj;
    }
    
    // leg
    //删去了随着上下形变的效果。TODO：前后摇摆时脚的位置应该发生变化
    {
    float sy = 0.5 + 0.3*bounceWave;
    float compress = 1.0-smoothstep(0.0,0.4,bounceWave);
    sy = sy*(1.0-compress) + compress;
    float sx = 1./sy;
    
    vec3 legPos = vec3(0.11, -0.17, 0.05);
    legPos = symmBody - legPos;
    legPos.y += 0.2* legPos.x*legPos.x; //脚底有比较扁
    
    float t6 = cos(6.2831*(atime*0.5+0.25));
    legPos.xz =rotMat(-1.0) * legPos.xz ;    //八字型
    legPos.xy =rotMat(t6*sign(basic.x)) * legPos.xy ; //随时间前后摇摆
        
    float dleg = sdEllipsoid( legPos, vec3(0.43, 0.18, 0.28)*0.3 );
    vec4 legObj = vec4(dleg, 3.0, objXY);
    
    res = opU(res, legObj);
    }
    
    
    //eye
    vec3 eyePos = vec3(0.06, 0.05, 0.19-2.*basic.y*basic.y);
    eyePos = symmBody - eyePos;
    
    eyePos.xz = rotMat(0.32)*eyePos.xz;//更贴合脸部
    
    float ss = min(1.,mod(atime,3.1));
    float sss = 1.- (smoothstep(0.,0.1,ss)-smoothstep(0.18,0.4,ss));
    
    float dEye = sdEllipsoid( eyePos, vec3(0.15, 0.3*sss+0.001, 0.03*sss+0.001)*0.2 );
    //float dEye = sdEllipsoid( eyePos, vec3(0.15, 0.3, 0.05)*0.2 );
    vec4 eyeObj = vec4(dEye, 4.0, eyePos.xy);
    
    //return eyeObj;
    res = opU(res, eyeObj);
    
     //eyeball
    vec3 eyeballPos = vec3(0.06, 0.075, (0.2-2.*basic.y*basic.y));
    eyeballPos = symmBody - eyeballPos;
    
    //float dEyeball = sdSphere( eyeballPos, 0.02 );
    float dEyeball = sdEllipsoid( eyeballPos, vec3(0.018*sss+0.0001, 0.023*sss+0.0001, 0.007*sss+0.0001) );
    vec4 eyeballObj = vec4(dEyeball, 5.0, eyeballPos.xy);
    //res = opU(res, eyeballObj);
    
    //vec3 eyePos = vec3(0.06, 0.05, 0.17);
    //eyePos = symmBody - eyePos;
    
    //float dEye = sdEllipse(eyePos.xy, vec2(0.15, 0.3));
    //vec2 eyeObj = vec2(dEye, 4.0);
    //res = opU(res, eyeObj);
    
    
    
    
    // ground
    
    float floorHeight = -0.1 //基础高度
                                     - 0.05*(sin(pos.x*2.0)+sin(pos.z*2.0)); //地形
    float t5 = fract(atime+0.05);
    float k = length(pos.xz-cen.xz);
    float t2 = t5*15.0-6.2831 - k*3.0;
    floorHeight -= 0.1*exp(-k*k)*sin(t2)*exp(-max(t2,0.0)/2.0)*smoothstep(0.0,0.01,t5);
     float dFloor = pos.y - floorHeight;
    
    
    // bubbles
    
    vec3 bubbleArea = vec3( mod(abs(pos.x),3.0),pos.y,mod(pos.z+1.5,3.0)-1.5);
        //随机生成
    vec2 id = vec2( floor(pos.x/3.0), floor((pos.z+1.5)/3.0) );
    float fid = id.x*11.1 + id.y*31.7;
        //飘起来的效果
    float fy = fract(fid*1.312+atime*0.1);
    float y = -1.0+4.0*fy;
    
    vec3  rad = vec3(0.7,1.0+0.5*sin(fid),0.7);
    rad -= 0.1*(sin(pos.x*3.0)+sin(pos.y*4.0)+sin(pos.z*5.0));    
    
        //smoothly  change the size when fly
   float siz = 4.0*fy*(1.0-fy);
    float dTree = sdEllipsoid( bubbleArea-vec3(2.0,y,0.0), rad*siz );
        //添加突出效果
    float bubbleTexture = 0.2*(-1.0+2.0*smoothstep(-0.2,0.2, sin(18.0*pos.x)+sin(18.0*pos.y)+sin(18.0*pos.z))); 
    dTree += 0.01 * bubbleTexture;
    
    dTree *= 0.6;
    dTree = min(dTree,2.0);

    dFloor = smin( dFloor, dTree, 0.32 );
    vec4 floorObj = vec4(dFloor, 1.0, objXY);
    
    res = opU(res, floorObj);
    
    
    //donuts
    {
    float fs = 5.0;
    vec3 qos = fs*vec3(pos.x, pos.y-floorHeight-0.02, pos.z );
    vec2 id = vec2( floor(qos.x+0.5), floor(qos.z+0.5) );
    
    vec3 vp = vec3( fract(qos.x+0.5)-0.5,qos.y,fract(qos.z+0.5)-0.5);
    vp.xz += 0.1*cos( id.x*130.143 + id.y*120.372 + vec2(0.0,2.0) );
    
    float den = sin(id.x*0.1+sin(id.y*0.091))+sin(id.y*0.1);
    float fid = id.x*0.143 + id.y*0.372;
    float ra = smoothstep(0.0,0.1,den*0.1+fract(fid)-0.9);
    
    float dDonut = sdDonut(vp, 0.24*ra)/fs;
    float dCream = sdCream(vp, 0.24*ra)/fs;
    //float dCandy = sdSphere( vp, 0.35*ra )/fs;
    vec4 donutObj = vec4(dDonut, 6.0, objXY);
    vec4 creamObj = vec4(dCream, 7.0, objXY);
    
    res = opU(res, donutObj);
    res = opU(res, creamObj);
    }
    
    return res;
}

//光线跟踪技术
vec4 castRay( in vec3 ro, in vec3 rd, float time )
{
    vec4 res = vec4(-1.0,-1.0, 0., 0.);

    float tmin = 0.5;
    float tmax = 20.0;
    
    float t = tmin;
    for( int i=0; i<256 && t<tmax; i++ )
    {
        vec4 h = map( ro+rd*t, time );
        if( abs(h.x)<(0.0005*t) )
        { 
            res = vec4(t,h.yzw); 
            break;
        }
        t += h.x;
    }
    
    return res;
}


//归一化函数
vec3 calcNormal( in vec3 pos, float time )
{
/*
    vec2 e = vec2(0.0005,0.0);
    return normalize( vec3( 
        map( pos + e.xyy, time ).x - map( pos - e.xyy, time ).x,
		map( pos + e.yxy, time ).x - map( pos - e.yxy, time ).x,
		map( pos + e.yyx, time ).x - map( pos - e.yyx, time ).x ) );
*/
    vec3 n = vec3(0.0);
    for( int i=min(iFrame,0); i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+0.0005*e,time).x;
    }
    return normalize(n);    
}


float calcOcclusion( in vec3 pos, in vec3 nor, float time )
{
	float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.01 + 0.11*float(i)/4.0;
        vec3 opos = pos + h*nor;
        float d = map( opos, time ).x;
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 2.0*occ, 0.0, 1.0 );
}

//颜色渲染
vec3 render( in vec3 ro, in vec3 rd, float time )
{ 
    // sky dome
    vec3 col = vec3(0.5, 0.8, 0.9) - max(rd.y,0.0)*0.5;
    
    vec4 res = castRay(ro,rd, time);
    if( res.y>-0.5 )
    {
        float t = res.x;
        vec2 objXY = res.zw;
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal( pos, time );
        vec3 ref = reflect( rd, nor );
        
        //渲染颜色
		col = vec3(0.2);
        float ks = 1.0;

        if (res.y > 6.5)  //cream
        {
            col = vec3(0.14,0.048,0.0); 
             vec2 id = floor(5.0*pos.xz+0.5);
		     col += 0.13*cos((id.x*11.1+id.y*37.341) + vec3(1.0,1.0,1.0) );
             col = max(col,0.0);
            //col = vec3(0.639,0.302,0.549);
          
        }
        else if (res.y > 5.5)  //candy
        {
            col = vec3(0.14,0.048,0.0); 
             vec2 id = floor(5.0*pos.xz+0.5);
		     col += 0.036*cos((id.x*11.1+id.y*37.341) + vec3(0.0,1.0,2.0) );
             col = max(col,0.0);
        }
        else if (res.y > 4.5) ///eyeball
        {
            col = vec3(0.365,0.541,0.898);
            //col = vec3(0.,0.,0.875);
            
            vec2 ab = vec2(1.,2.); 
            float eyeCircle = (objXY.x*objXY.x)/(ab.x*ab.x) + (objXY.y*objXY.y)/(ab.y*ab.y);
            
            
            if (eyeCircle< 0.0001){
            //if (objXY.y<0.0001) {
                col = vec3(1.);
            }
            
        }
        else if( res.y>3.5 ) // eye
        {  // todo: 渐变色:需要返回相对坐标不能使用绝对坐标
            vec3 black = vec3(0.0);
            vec3 blue = vec3(0.0,0.0,1.0);
            col = (1.0 - vec3(smoothstep(-0.2,0.,objXY.y))) * blue;
            
            vec2 ab = vec2(0.0,0.02);
             float eyeBall = pow(objXY.x-ab.x,2.0)/1. + pow(objXY.y-ab.y,2.0)/4.;
             if (eyeBall < 0.0002){col = vec3(1.0);}
            //if (eyeLight < 0.00005){col = vec3(0.278,0.278,1.000);}

            //vec2 circleP = vec2(0.07, 1.06);
            //float xx = (abs(objXY.x) - circleP.x)*(abs(objXY.x) - circleP.x);
            //float yy = (objXY.y - circleP.y)*(objXY.y - circleP.y);
            //col = vec3(0.0,0.0,1.0);
            //if ( objXY.y < 0.0003){col = blue;}
            
            //col = vec3(0.0);
        } 
        else if( res.y>2.5 ) // leg
        { 
            col = vec3(0.4,0.0,0.02);
        } 
        else if( res.y>1.5 ) // body
        { 
            col = vec3(0.5,0.07,0.1);
            if (objXY.x > -0.5){
            
                vec3 bodyCol = vec3(0.5,0.07,0.1);
                vec3 blusherCol = vec3(0.686,0.031,0.067);
                vec3 mouthCol = vec3(0.561,0.020,0.047);

                vec2 ab = vec2(0.12,-0.02); 
                float blusher = pow(objXY.x-ab.x,2.0)/4. + pow(objXY.y-ab.y,2.0)/1.;
                col = mix(blusherCol, bodyCol, smoothstep(0.0001, 0.0002, blusher));
                
                float mouth = pow(objXY.x,2.0)/4. + pow(objXY.y-12.*pow(objXY.x, 2.0)+0.04,2.0)/4.;
                if (mouth < 0.00015){col = mouthCol;}

               //if (blusher<0.0001){col = vec3(0.686,0.031,0.067); }
               //else if (blusher<0.0002){}
           }
            
        }
		else // terrain
        {
            col = vec3(0.05,0.09,0.02);
            
            //格子颜色
            float wave  = sin(18.0*pos.x)+sin(18.0*pos.y)+sin(18.0*pos.z); //生成黑白相间的颜色
            float f = 0.2*(-1.0+2.0*smoothstep(-0.2,0.2,wave)); //让wave变得更加锋利，颜色变化更剧烈
            col += f*vec3(0.06,0.06,0.02);
            
            //提高亮度：对阳光反射亮度进行了加强
            ks = 0.5 + pos.y*0.15;
        }
        
        // lighting
        vec3  sun_lig = normalize( vec3(0.6, 0.35, 0.5) );
        float sun_dif = clamp(dot( nor, sun_lig ), 0.0, 1.0 );
        vec3  sun_hal = normalize( sun_lig-rd );
        float sun_sha = step(castRay( pos+0.001*nor, sun_lig,time ).y,0.0);
		float sun_spe = ks*pow(clamp(dot(nor,sun_hal),0.0,1.0),8.0)*sun_dif*(0.04+0.96*pow(clamp(1.0+dot(sun_hal,rd),0.0,1.0),5.0));
		float sky_dif = sqrt(clamp( 0.5+0.5*nor.y, 0.0, 1.0 ));
        float bou_dif = sqrt(clamp( 0.1-0.9*nor.y, 0.0, 1.0 ))*clamp(1.0-0.1*pos.y,0.0,1.0);

		vec3 lin = vec3(0.0);
        lin += sun_dif*vec3(8.10,6.00,4.20)*sun_sha;
        lin += sky_dif*vec3(0.50,0.70,1.00);
        lin += bou_dif*vec3(0.40,1.00,0.40);
		col = col*lin;
		col += sun_spe*vec3(8.10,6.00,4.20)*sun_sha;
        
        col = mix( col, vec3(0.5,0.7,0.9), 1.0-exp( -0.0001*t*t*t ) );
    }

    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //转换坐标，实现1. 位于中心 2.比例与画布长宽相同
    vec2 p = (-iResolution.xy + 2.0*fragCoord)/iResolution.y;
    float time = iTime;
    //float time = 1.;
    time *= 0.9;

    // camera	
    //float an = 0.;
    float an = 10.*iMouse.x/iResolution.x;
    
    float forwardWave = sin(0.5*time);
    float smoothForward = -1.
                                            +time*1.0 - 0.4*forwardWave; //虽然依旧是线性前进但是有个动态的微小波动更显真实
    vec3  ta = vec3( 0.0, 0.65, smoothForward);
    //vec3  ta = vec3( 0.0, 0.95, 0.);  //如果用这个就不会发生拖动的时候的位置移动
    vec3  ro = ta + vec3( 1.5*cos(an), 0.0, 1.5*sin(an) ); // 摄像机位置
    
    // camera bounce
    float t4 = abs(fract(time*0.5)-0.5)/0.5;
    float bou = -1.0 + 2.0*t4;
    ro += 0.03 //weight
                *sin(time*12.0+vec3(0.0,2.0,4.0))*smoothstep( 0.85, 1.0, abs(bou) );

    // 相机方向的变换矩阵
	vec3 cw = normalize(ta-ro); //(lookatPoint - original) 相机方向向量：前向向量
	vec3 cp = vec3(0.0, 1.0,0.0); 
	vec3 cu = normalize( cross(cw,cp) ); // 利用cp求出向右的向量
	vec3 cv =          ( cross(cu,cw) ); //反推回真正的向上的向量

    //得到最终的相机方向
    vec3 rd = normalize( p.x*cu + p.y*cv + 1.8*cw ); //得到可以移动的

    vec3 col = render( ro, rd, time );

    col = pow( col, vec3(0.4545) ); //加强颜色效果

    fragColor = vec4( col, 1.0 );
}