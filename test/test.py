import os
import numpy as np
import tflite_runtime.interpreter as tflite


def load_tflite_model_function(model_path, **kw):
    compute = prepare_model_function(tflite.Interpreter(model_path), **kw)
    compute.model_path = model_path
    return compute


def prepare_model_function(model, verbose=False):
    # assumes a single input and output
    in_dets = model.get_input_details()[0]
    out_dets = model.get_output_details()[0]

    model.allocate_tensors()
    def compute(x):
        # set inputs
        model.set_tensor(in_dets['index'], x.astype(in_dets['dtype']))
        # compute outputs
        model.invoke()
        # get outputs
        return model.get_tensor(out_dets['index'])

    if verbose:
        print('-- Input details --')
        print(in_dets, '\n')
        print('-- Output details --')
        print(out_dets, '\n')

    # set input and output shapes so they're easily accessible
    compute.input_shape = in_dets['shape'][1:]
    compute.output_shape = out_dets['shape'][1:]
    return compute



def main():
    compute = load_tflite_model_function(
        os.path.join(os.path.dirname(__file__), 'basic.tflite'))
    y = compute(np.random.randn(1, *compute.input_shape))
    assert y.shape == tuple(compute.output_shape)



if __name__ == '__main__':
    main()
